BEGIN;

-- Se eliminan solo los procedimientos que ya no forman parte del script.
-- Los dos procedimientos vigentes se reemplazan con CREATE OR REPLACE para
-- conservar sus permisos de ejecución.
DROP PROCEDURE IF EXISTS sp_movie_delete;
DROP PROCEDURE IF EXISTS sp_person_merge;
DROP PROCEDURE IF EXISTS sp_register_release;

-- 1. modificación de películas

-- Reglas de negocio:
--      - nombre obligatorio y no vacío.
--      - año en el rango histórico admitido.
--      - admitido, duración positiva.
--      - rating entre 0 y 5.

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
        ROLLBACK;
        RAISE EXCEPTION 'movie_id inválido: %', p_movie_id
            USING ERRCODE = '22023';
    END IF;

    IF p_name IS NULL OR btrim(p_name) = '' THEN
        ROLLBACK;
        RAISE EXCEPTION 'El nombre de la película no puede estar vacío'
            USING ERRCODE = '22023';
    END IF;

    IF p_release_year IS NOT NULL AND p_release_year NOT BETWEEN 1870 AND 2100 THEN
        ROLLBACK;
        RAISE EXCEPTION 'Año de estreno fuera de rango (1870-2100): %', p_release_year
            USING ERRCODE = '22023';
    END IF;

    IF p_minute IS NOT NULL AND p_minute <= 0 THEN
        ROLLBACK;
        RAISE EXCEPTION 'La duración debe ser mayor que cero: %', p_minute
            USING ERRCODE = '22023';
    END IF;

    IF p_rating IS NOT NULL AND p_rating NOT BETWEEN 0 AND 5 THEN
        ROLLBACK;
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
            ROLLBACK;
            RAISE EXCEPTION 'No se pudo guardar la película %: %',
                p_movie_id, SQLERRM
                USING ERRCODE = 'P0001';
    END;

    COMMIT;
END;
$$;

-- 2. Eiminación de estudios

-- Reglas de negocio:
--      - No se permite eliminar un estudio que tenga películas asociadas:
--        primero debe desvincularse o reasignarse.
--        Si la regla se cumple, se elimina.

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

COMMIT;
