-- Pasar releases.csv a release_types, certifications y releases.

BEGIN;

INSERT INTO release_types (name)
SELECT DISTINCT type
FROM staging.stg_releases;

INSERT INTO certifications (name)
SELECT DISTINCT rating
FROM staging.stg_releases
WHERE rating <> '';

INSERT INTO releases (
    movie_id, country_id, release_date, release_type_id, certification_id
)
SELECT
    r.id,
    c.country_id,
    r.date::DATE,
    rt.release_type_id,
    ce.certification_id
FROM staging.stg_releases r
JOIN countries c ON c.name = r.country
JOIN release_types rt ON rt.name = r.type
LEFT JOIN certifications ce ON ce.name = r.rating;

COMMIT;
