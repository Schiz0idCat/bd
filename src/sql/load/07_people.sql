-- Pasar actores y crew a la tabla people.
-- UNION ya elimina los nombres repetidos.

BEGIN;

INSERT INTO people (name)
SELECT name FROM staging.stg_actors
UNION
SELECT name FROM staging.stg_crew;

COMMIT;
