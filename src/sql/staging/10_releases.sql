-- ============================================================================
-- STAGING: releases.csv
-- ============================================================================

DROP TABLE IF EXISTS staging.stg_releases;

CREATE UNLOGGED TABLE staging.stg_releases (
    id      INTEGER,
    country TEXT,
    date    TEXT,
    type    TEXT,
    rating  TEXT
);

\copy staging.stg_releases FROM 'data/releases.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
