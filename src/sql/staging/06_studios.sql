-- ============================================================================
-- STAGING: studios.csv
-- ============================================================================

DROP TABLE IF EXISTS staging.stg_studios;

CREATE UNLOGGED TABLE staging.stg_studios (
    id     INTEGER,
    studio TEXT
);

\copy staging.stg_studios FROM 'data/studios.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
