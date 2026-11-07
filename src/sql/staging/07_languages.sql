-- ============================================================================
-- STAGING: languages.csv
-- ============================================================================

DROP TABLE IF EXISTS staging.stg_languages;

CREATE UNLOGGED TABLE staging.stg_languages (
    id       INTEGER,
    type     TEXT,
    language TEXT
);

\copy staging.stg_languages FROM 'data/languages.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
