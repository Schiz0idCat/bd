-- Pasar studios.csv a studios y movie_studios.

BEGIN;

INSERT INTO studios (name)
SELECT DISTINCT studio
FROM staging.stg_studios;

INSERT INTO movie_studios (movie_id, studio_id)
SELECT DISTINCT s.id, st.studio_id
FROM staging.stg_studios s
JOIN studios st ON st.name = s.studio;

COMMIT;
