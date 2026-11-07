-- Pasar genres.csv a genres y movie_genres.

BEGIN;

INSERT INTO genres (name)
SELECT DISTINCT genre
FROM staging.stg_genres;

INSERT INTO movie_genres (movie_id, genre_id)
SELECT DISTINCT s.id, g.genre_id
FROM staging.stg_genres s
JOIN genres g ON g.name = s.genre;

COMMIT;
