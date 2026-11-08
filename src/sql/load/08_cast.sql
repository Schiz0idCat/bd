-- Pasar actors.csv a movie_cast.

BEGIN;

INSERT INTO movie_cast (movie_id, person_id, character_name)
SELECT DISTINCT
    a.id,
    p.person_id,
    NULLIF(a.role, '')
FROM staging.stg_actors a
JOIN people p ON p.name = a.name;

COMMIT;
