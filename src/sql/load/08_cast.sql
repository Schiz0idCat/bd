-- Pasar actors.csv a movie_cast.
-- Si el rol viene vacío se guarda como NULL.

BEGIN;

INSERT INTO movie_cast (movie_id, person_id, character_name)
SELECT DISTINCT
    a.id,
    p.person_id,
    NULLIF(a.role, '')
FROM staging.stg_actors a
JOIN people p ON p.name = a.name;

COMMIT;
