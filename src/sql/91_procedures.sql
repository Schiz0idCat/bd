-- ============================================================================
-- PROCEDIMIENTOS ALMACENADOS (MANTENEDORES)
-- ============================================================================
-- Se aplican después de crear el modelo (init.sql), antes o después de cargar
-- los datos. No dependen del staging.
--
--   psql -d peliculas -f src/sql/91_procedures.sql
--
-- Convención de transacciones:
--   * Éxito  -> COMMIT explícito dentro del procedimiento.
--   * Error  -> ROLLBACK explícito (regla de negocio) o RAISE EXCEPTION, que
--               aborta la transacción del llamador.
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. Alta / modificación de películas
-- ============================================================================
-- Reglas de negocio: nombre obligatorio y no vacío, año en el rango histórico
-- admitido, duración positiva y rating entre 0 y 5.
-- ============================================================================

CREATE OR REPLACE PROCEDURE sp_movie_upsert(
    p_movie_id      INTEGER,
    p_name          VARCHAR,
    p_release_year  INTEGER  DEFAULT NULL,
    p_tagline       VARCHAR  DEFAULT NULL,
    p_description   TEXT     DEFAULT NULL,
    p_minute        INTEGER  DEFAULT NULL,
    p_rating        NUMERIC  DEFAULT NULL,
    p_poster_link   TEXT     DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_movie_id IS NULL OR p_movie_id <= 0 THEN
        RAISE EXCEPTION 'movie_id inválido: %', p_movie_id
            USING ERRCODE = '22023';
    END IF;

    IF p_name IS NULL OR btrim(p_name) = '' THEN
        RAISE EXCEPTION 'El nombre de la película no puede estar vacío'
            USING ERRCODE = '22023';
    END IF;

    IF p_release_year IS NOT NULL AND p_release_year NOT BETWEEN 1870 AND 2100 THEN
        RAISE EXCEPTION 'Año de estreno fuera de rango (1870-2100): %', p_release_year
            USING ERRCODE = '22023';
    END IF;

    IF p_minute IS NOT NULL AND p_minute <= 0 THEN
        RAISE EXCEPTION 'La duración debe ser mayor que cero: %', p_minute
            USING ERRCODE = '22023';
    END IF;

    IF p_rating IS NOT NULL AND p_rating NOT BETWEEN 0 AND 5 THEN
        RAISE EXCEPTION 'El rating debe estar entre 0 y 5: %', p_rating
            USING ERRCODE = '22023';
    END IF;

    BEGIN
        INSERT INTO movies (
            movie_id, name, release_year, tagline, description,
            minute, rating, poster_link
        )
        VALUES (
            p_movie_id, p_name, p_release_year::SMALLINT, p_tagline, p_description,
            p_minute, p_rating, p_poster_link
        )
        ON CONFLICT (movie_id) DO UPDATE SET
            name         = EXCLUDED.name,
            release_year = EXCLUDED.release_year,
            tagline      = EXCLUDED.tagline,
            description  = EXCLUDED.description,
            minute       = EXCLUDED.minute,
            rating       = EXCLUDED.rating,
            poster_link  = EXCLUDED.poster_link;
    EXCEPTION
        WHEN check_violation OR not_null_violation OR unique_violation THEN
            RAISE EXCEPTION 'No se pudo guardar la película %: %',
                p_movie_id, SQLERRM
                USING ERRCODE = 'P0001';
    END;

    COMMIT;
END;
$$;

-- ============================================================================
-- 2. Baja de películas
-- ============================================================================
-- Las relaciones (reparto, crew, géneros, estrenos, etc.) se eliminan por
-- ON DELETE CASCADE.
-- ============================================================================

CREATE OR REPLACE PROCEDURE sp_movie_delete(p_movie_id INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM movies WHERE movie_id = p_movie_id) THEN
        ROLLBACK;
        RAISE EXCEPTION 'La película % no existe', p_movie_id
            USING ERRCODE = 'P0002';
    END IF;

    DELETE FROM movies WHERE movie_id = p_movie_id;

    COMMIT;
END;
$$;

-- ============================================================================
-- 3. Baja de estudios con regla de negocio
-- ============================================================================
-- No se permite eliminar un estudio que tenga películas asociadas: primero
-- debe desvincularse o reasignarse. Si la regla se cumple, se elimina.
-- ============================================================================

CREATE OR REPLACE PROCEDURE sp_studio_delete(p_studio_id INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_movies BIGINT;
BEGIN
    SELECT count(*) INTO v_movies
    FROM movie_studios
    WHERE studio_id = p_studio_id;

    IF v_movies > 0 THEN
        ROLLBACK;
        RAISE EXCEPTION
            'No se puede eliminar el estudio %: tiene % película(s) asociada(s)',
            p_studio_id, v_movies
            USING ERRCODE = 'P0001';
    END IF;

    DELETE FROM studios WHERE studio_id = p_studio_id;

    IF NOT FOUND THEN
        ROLLBACK;
        RAISE EXCEPTION 'El estudio % no existe', p_studio_id
            USING ERRCODE = 'P0002';
    END IF;

    COMMIT;
END;
$$;

-- ============================================================================
-- 4. Fusión de personas duplicadas
-- ============================================================================
-- Mueve el reparto y el crew de la persona duplicada hacia la persona que se
-- conserva, y luego elimina el duplicado. Todo ocurre en una transacción.
-- ============================================================================

CREATE OR REPLACE PROCEDURE sp_person_merge(
    p_keep_id   BIGINT,
    p_remove_id BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_keep_id = p_remove_id THEN
        ROLLBACK;
        RAISE EXCEPTION 'No se puede fusionar una persona consigo misma (%)',
            p_keep_id
            USING ERRCODE = '22023';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM people WHERE person_id = p_keep_id) THEN
        ROLLBACK;
        RAISE EXCEPTION 'La persona a conservar % no existe', p_keep_id
            USING ERRCODE = 'P0002';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM people WHERE person_id = p_remove_id) THEN
        ROLLBACK;
        RAISE EXCEPTION 'La persona a eliminar % no existe', p_remove_id
            USING ERRCODE = 'P0002';
    END IF;

    BEGIN
        INSERT INTO movie_cast (movie_id, person_id, character_name)
        SELECT movie_id, p_keep_id, character_name
        FROM movie_cast
        WHERE person_id = p_remove_id
        ON CONFLICT DO NOTHING;

        DELETE FROM movie_cast WHERE person_id = p_remove_id;

        INSERT INTO movie_crew (movie_id, person_id, crew_role_id)
        SELECT movie_id, p_keep_id, crew_role_id
        FROM movie_crew
        WHERE person_id = p_remove_id
        ON CONFLICT DO NOTHING;

        DELETE FROM movie_crew WHERE person_id = p_remove_id;

        DELETE FROM people WHERE person_id = p_remove_id;
    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Fusión cancelada: %', SQLERRM
                USING ERRCODE = 'P0001';
    END;

    COMMIT;
END;
$$;

-- ============================================================================
-- 5. Registro de estrenos con regla de negocio
-- ============================================================================
-- La fecha del estreno no puede ser anterior al año de la película (se admite
-- un año de tolerancia por preestrenos y festivales). Los catálogos que no
-- existan se crean automáticamente.
-- ============================================================================

CREATE OR REPLACE PROCEDURE sp_register_release(
    p_movie_id      INTEGER,
    p_country       VARCHAR,
    p_release_date  DATE,
    p_type          VARCHAR,
    p_certification VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_year     SMALLINT;
    v_country  SMALLINT;
    v_type     SMALLINT;
    v_cert     SMALLINT;
BEGIN
    IF p_movie_id IS NULL OR p_country IS NULL OR p_type IS NULL
       OR p_release_date IS NULL THEN
        RAISE EXCEPTION 'Película, país, fecha y tipo son obligatorios'
            USING ERRCODE = '22023';
    END IF;

    SELECT release_year INTO v_year
    FROM movies
    WHERE movie_id = p_movie_id;

    IF NOT FOUND THEN
        ROLLBACK;
        RAISE EXCEPTION 'La película % no existe', p_movie_id
            USING ERRCODE = 'P0002';
    END IF;

    IF v_year IS NOT NULL
       AND EXTRACT(YEAR FROM p_release_date) < v_year - 1 THEN
        ROLLBACK;
        RAISE EXCEPTION
            'Estreno inválido: la película es de % y el estreno es del %',
            v_year, p_release_date
            USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO countries (name) VALUES (p_country)
    ON CONFLICT (name) DO NOTHING;
    SELECT country_id INTO v_country FROM countries WHERE name = p_country;

    INSERT INTO release_types (name) VALUES (p_type)
    ON CONFLICT (name) DO NOTHING;
    SELECT release_type_id INTO v_type FROM release_types WHERE name = p_type;

    IF p_certification IS NOT NULL AND btrim(p_certification) <> '' THEN
        INSERT INTO certifications (name) VALUES (p_certification)
        ON CONFLICT (name) DO NOTHING;
        SELECT certification_id INTO v_cert
        FROM certifications WHERE name = p_certification;
    END IF;

    BEGIN
        INSERT INTO releases (
            movie_id, country_id, release_date, release_type_id,
            certification_id
        )
        VALUES (p_movie_id, v_country, p_release_date, v_type, v_cert);
    EXCEPTION
        WHEN unique_violation THEN
            RAISE EXCEPTION
                'La película % ya tiene un estreno % en % el %',
                p_movie_id, p_type, p_country, p_release_date
                USING ERRCODE = 'P0001';
    END;

    COMMIT;
END;
$$;

COMMIT;
