-- ============================================================================
-- STAGING: movies.csv
-- ============================================================================

DROP TABLE IF EXISTS staging.stg_movies;

CREATE UNLOGGED TABLE staging.stg_movies (
    id          INTEGER,
    name        TEXT,
    date        TEXT,
    tagline     TEXT,
    description TEXT,
    minute      TEXT,
    rating      TEXT
);

\copy staging.stg_movies FROM 'data/movies.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
