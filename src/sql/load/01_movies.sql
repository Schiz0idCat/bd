-- Pasar movies.csv y posters.csv a la tabla movies.

BEGIN;

INSERT INTO movies (
    movie_id, name, release_year, tagline, description,
    minute, rating, poster_link
)
SELECT
    m.id,
    m.name,
    NULLIF(m.date, '')::SMALLINT,
    NULLIF(m.tagline, ''),
    NULLIF(m.description, ''),
    NULLIF(m.minute, '')::INTEGER,
    NULLIF(m.rating, '')::NUMERIC(3,2),
    NULLIF(p.link, '')
FROM staging.stg_movies m
LEFT JOIN staging.stg_posters p ON p.id = m.id;

COMMIT;
