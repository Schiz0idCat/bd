-- countries.csv

DROP TABLE IF EXISTS staging.stg_countries;

CREATE UNLOGGED TABLE staging.stg_countries (
    id      INTEGER,
    country TEXT
);

\copy staging.stg_countries FROM 'data/countries.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
