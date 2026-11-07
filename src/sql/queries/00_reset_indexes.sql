-- ============================================================================
-- RESTAURA LOS ÍNDICES BASE
-- ============================================================================
-- Permite repetir la comparación de planes desde el mismo punto de partida.
-- ============================================================================

BEGIN;

DROP INDEX IF EXISTS idx_movie_genres_genre_movie;
DROP INDEX IF EXISTS idx_movie_countries_country_movie;
DROP INDEX IF EXISTS idx_movies_year_rating;

CREATE INDEX IF NOT EXISTS idx_movie_genres_genre
    ON movie_genres (genre_id);
CREATE INDEX IF NOT EXISTS idx_movie_countries_country
    ON movie_countries (country_id);

COMMIT;

ANALYZE movie_genres;
ANALYZE movie_countries;
ANALYZE movies;
