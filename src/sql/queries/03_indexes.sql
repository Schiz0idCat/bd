-- ============================================================================
-- ÍNDICES DE OPTIMIZACIÓN
-- ============================================================================
-- Se aplican después de medir los planes con el esquema base.
--
-- El índice que realmente ayuda es el de (release_year, rating): permite un
-- Index Only Scan para el filtro de año y rating y devuelve movie_id y name
-- sin visitar el heap. Luego los JOIN resuelven país y género por las claves
-- primarias (movie_id, ...).
--
-- Los índices por country_id y genre_id se eliminan porque hacen que el
-- planificador parta del catálogo y recorra cientos de miles de filas, lo que
-- resultó más lento que partir de las películas filtradas.
--
--   psql -d peliculas -f src/sql/queries/03_indexes.sql
-- ============================================================================

BEGIN;

DROP INDEX IF EXISTS idx_movie_genres_genre_movie;
DROP INDEX IF EXISTS idx_movie_countries_country_movie;
DROP INDEX IF EXISTS idx_movie_genres_genre;
DROP INDEX IF EXISTS idx_movie_countries_country;

CREATE INDEX IF NOT EXISTS idx_movies_year_rating
    ON movies (release_year, rating) INCLUDE (movie_id, name);

COMMIT;

ANALYZE movie_genres;
ANALYZE movie_countries;
ANALYZE movies;
