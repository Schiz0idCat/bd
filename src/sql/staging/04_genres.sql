-- ============================================================================
-- STAGING: genres.csv
-- ============================================================================

DROP TABLE IF EXISTS staging.stg_genres;

CREATE UNLOGGED TABLE staging.stg_genres (
    id    INTEGER,
    genre TEXT
);

\copy staging.stg_genres FROM 'data/genres.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
