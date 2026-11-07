-- Pasar countries.csv a countries y movie_countries.

BEGIN;

INSERT INTO countries (name)
SELECT DISTINCT country
FROM staging.stg_countries;

INSERT INTO movie_countries (movie_id, country_id)
SELECT DISTINCT s.id, c.country_id
FROM staging.stg_countries s
JOIN countries c ON c.name = s.country;

COMMIT;
