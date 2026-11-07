-- ============================================================================
-- PRUEBAS DE OBJETOS: AUDITORÍA, PROCEDIMIENTOS, VISTAS Y PERMISOS
-- ============================================================================
-- Ejecutar con:
--   psql -d peliculas -f src/sql/94_tests.sql
--
-- Las pruebas que deben fallar se marcan con "DEBE FALLAR". ON_ERROR_STOP se
-- desactiva a propósito para poder mostrar el error y continuar.
-- ============================================================================

\set ON_ERROR_STOP off

\echo '-- Limpieza inicial (permite repetir las pruebas)'
DELETE FROM movies WHERE movie_id = 999999999;
DELETE FROM people WHERE name IN ('Persona Duplicada A', 'Persona Duplicada B');
DELETE FROM studios WHERE name = 'Estudio Temporal de Prueba';

\echo ''
\echo '============================================================'
\echo ' 1. Auditoría: alta, modificación y baja de una película'
\echo '============================================================'

CALL sp_movie_upsert(
    999999999,
    'Película de prueba',
    2000,
    'Tagline de prueba',
    'Descripción de prueba',
    90,
    3.50,
    'https://example.com/poster.jpg'
);

UPDATE movies SET rating = 4.25 WHERE movie_id = 999999999;

SELECT operation, row_key, db_user
FROM audit_log
WHERE table_name = 'movies'
  AND row_key ->> 'movie_id' = '999999999'
ORDER BY audit_id;

\echo ''
\echo '============================================================'
\echo ' 2. Regla de negocio: rating fuera de rango (DEBE FALLAR)'
\echo '============================================================'

CALL sp_movie_upsert(999999999, 'Película de prueba', 2000, NULL, NULL, 90, 7.00, NULL);

\echo '-- El rating debe seguir en 4.25:'
SELECT movie_id, rating FROM movies WHERE movie_id = 999999999;

\echo ''
\echo '============================================================'
\echo ' 3. Regla de negocio: no borrar estudio con películas (DEBE FALLAR)'
\echo '============================================================'

SELECT COALESCE(
    (SELECT studio_id FROM movie_studios LIMIT 1),
    -1
) AS sid
\gset

CALL sp_studio_delete(:sid);

\echo ''
\echo '============================================================'
\echo ' 4. Baja de un estudio sin películas (DEBE FUNCIONAR)'
\echo '============================================================'

INSERT INTO studios (name)
VALUES ('Estudio Temporal de Prueba')
RETURNING studio_id AS tmp_sid
\gset

CALL sp_studio_delete(:tmp_sid);

SELECT count(*) AS estudios_restantes
FROM studios
WHERE studio_id = :tmp_sid;

\echo ''
\echo '============================================================'
\echo ' 5. Regla de negocio: estreno anterior a la película (DEBE FALLAR)'
\echo '============================================================'

CALL sp_register_release(
    999999999, 'Chile', DATE '1990-01-01', 'Theatrical'
);

\echo ''
\echo '============================================================'
\echo ' 6. Estreno válido (DEBE FUNCIONAR)'
\echo '============================================================'

CALL sp_register_release(
    999999999, 'Chile', DATE '2001-05-05', 'Theatrical', 'TE'
);

SELECT r.movie_id, c.name AS pais, r.release_date, rt.name AS tipo,
       ce.name AS certificacion
FROM releases r
JOIN countries c      ON c.country_id = r.country_id
JOIN release_types rt ON rt.release_type_id = r.release_type_id
LEFT JOIN certifications ce
                      ON ce.certification_id = r.certification_id
WHERE r.movie_id = 999999999;

\echo ''
\echo '============================================================'
\echo ' 7. Fusión de personas duplicadas'
\echo '============================================================'

INSERT INTO people (name) VALUES ('Persona Duplicada A')
RETURNING person_id AS persona_a \gset

INSERT INTO people (name) VALUES ('Persona Duplicada B')
RETURNING person_id AS persona_b \gset

INSERT INTO movie_cast (movie_id, person_id, character_name)
VALUES (999999999, :persona_b, 'Rol de prueba');

CALL sp_person_merge(:persona_a, :persona_b);

SELECT
    (SELECT count(*) FROM movie_cast WHERE person_id = :persona_b) AS filas_duplicado,
    (SELECT count(*) FROM movie_cast WHERE person_id = :persona_a) AS filas_conservado,
    (SELECT count(*) FROM people WHERE person_id = :persona_b)     AS persona_duplicado;

\echo ''
\echo '============================================================'
\echo ' 8. El log es append-only: UPDATE (DEBE FALLAR)'
\echo '============================================================'

UPDATE audit_log
SET db_user = 'intruso'
WHERE audit_id = (SELECT min(audit_id) FROM audit_log);

\echo ''
\echo '============================================================'
\echo ' 9. El log es append-only: TRUNCATE (DEBE FALLAR)'
\echo '============================================================'

TRUNCATE audit_log;

\echo ''
\echo '============================================================'
\echo ' 10. Permisos por rol'
\echo '============================================================'

\echo '-- bd_lectura: puede leer la vista pública'
SET ROLE bd_lectura;
SELECT count(*) AS peliculas_publicas FROM vw_movies_public;

\echo '-- bd_lectura: NO puede leer la tabla base (DEBE FALLAR)'
SELECT count(*) FROM movies;

\echo '-- bd_lectura: NO puede leer estrenos futuros desde la vista pública'
SELECT count(*) AS estrenos_futuros FROM vw_releases_public
WHERE release_date > CURRENT_DATE;
RESET ROLE;

\echo '-- bd_mantenedor: puede ejecutar procedimientos'
SET ROLE bd_mantenedor;
CALL sp_movie_upsert(999999999, 'Película de prueba', 2000, NULL, NULL, 90, 4.25, NULL);

\echo '-- bd_mantenedor: NO puede escribir catálogos que no mantiene (DEBE FALLAR)'
INSERT INTO genres (name) VALUES ('Género prohibido');
RESET ROLE;

\echo '-- bd_admin: puede leer las tablas base y el log'
SET ROLE bd_admin;
SELECT count(*) AS peliculas FROM movies;
SELECT count(*) AS registros_de_auditoria FROM audit_log;
RESET ROLE;

\echo ''
\echo '============================================================'
\echo ' 11. Limpieza de datos de prueba'
\echo '============================================================'

CALL sp_movie_delete(999999999);
DELETE FROM people WHERE person_id IN (:persona_a, :persona_b);

SELECT
    (SELECT count(*) FROM movies WHERE movie_id = 999999999) AS pelicula,
    (SELECT count(*) FROM people WHERE person_id IN (:persona_a, :persona_b)) AS personas,
    (SELECT count(*) FROM releases WHERE movie_id = 999999999) AS estrenos;

\echo ''
\echo 'Pruebas terminadas. Los registros de auditoría de la prueba se conservan'
\echo 'como evidencia (operation I/U/D sobre la película 999999999).'
