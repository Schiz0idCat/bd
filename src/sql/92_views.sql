BEGIN;

DROP VIEW IF EXISTS vw_movies_recent;
DROP VIEW IF EXISTS vw_releases_upcoming;

-- Oculta descripción y enlace de póster.

CREATE OR REPLACE VIEW vw_movies_public
WITH (security_barrier = true)
AS
SELECT
    m.movie_id,
    m.name,
    m.release_year,
    m.minute,
    m.rating,
    m.tagline
FROM movies m;

-- Solo estrenos ya ocurridos.

CREATE OR REPLACE VIEW vw_releases_public
WITH (security_barrier = true)
AS
SELECT
    r.movie_id,
    m.name            AS movie_name,
    c.name            AS country,
    r.release_date,
    rt.name           AS release_type,
    ce.name           AS certification
FROM releases r
JOIN movies m          ON m.movie_id = r.movie_id
JOIN countries c       ON c.country_id = r.country_id
JOIN release_types rt  ON rt.release_type_id = r.release_type_id
LEFT JOIN certifications ce
                       ON ce.certification_id = r.certification_id
WHERE r.release_date <= CURRENT_DATE;

COMMIT;
