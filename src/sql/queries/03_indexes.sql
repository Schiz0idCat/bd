-- indices para mejorar la consulta

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
