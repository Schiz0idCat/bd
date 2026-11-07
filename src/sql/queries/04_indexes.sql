-- ============================================================================
-- ÍNDICES DE OPTIMIZACIÓN
-- ============================================================================
-- Se aplican después de medir los planes con el esquema base. Los índices
-- compuestos permiten index-only scan y evitan visitar el heap.
--
--   psql -d peliculas -f src/sql/queries/04_indexes.sql
-- ============================================================================

BEGIN;

-- Género -> película: cubre el filtro por nombre de género y el movie_id.
CREATE INDEX IF NOT EXISTS idx_movie_genres_genre_movie
    ON movie_genres (genre_id, movie_id);

-- País -> película: cubre el filtro por país y el movie_id.
CREATE INDEX IF NOT EXISTS idx_movie_countries_country_movie
    ON movie_countries (country_id, movie_id);

-- Año y rating juntos, con las columnas del SELECT para index-only scan.
CREATE INDEX IF NOT EXISTS idx_movies_year_rating
    ON movies (release_year, rating) INCLUDE (movie_id, name);

-- Los índices de una sola columna quedan cubiertos por el prefijo de los
-- compuestos, por lo que se eliminan para no mantener estructuras redundantes.
DROP INDEX IF EXISTS idx_movie_genres_genre;
DROP INDEX IF EXISTS idx_movie_countries_country;

COMMIT;

ANALYZE movie_genres;
ANALYZE movie_countries;
ANALYZE movies;
