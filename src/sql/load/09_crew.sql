-- Pasar crew.csv a crew_roles y movie_crew.

BEGIN;

INSERT INTO crew_roles (name)
SELECT DISTINCT role
FROM staging.stg_crew;

INSERT INTO movie_crew (movie_id, person_id, crew_role_id)
SELECT DISTINCT
    c.id,
    p.person_id,
    r.crew_role_id
FROM staging.stg_crew c
JOIN people p ON p.name = c.name
JOIN crew_roles r ON r.name = c.role;

COMMIT;
