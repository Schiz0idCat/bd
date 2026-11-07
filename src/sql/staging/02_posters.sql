-- ============================================================================
-- STAGING: posters.csv
-- ============================================================================

DROP TABLE IF EXISTS staging.stg_posters;

CREATE UNLOGGED TABLE staging.stg_posters (
    id   INTEGER,
    link TEXT
);

\copy staging.stg_posters FROM 'data/posters.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
