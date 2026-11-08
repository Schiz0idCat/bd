-- crew.csv

DROP TABLE IF EXISTS staging.stg_crew;

CREATE UNLOGGED TABLE staging.stg_crew (
    id   INTEGER,
    role TEXT,
    name TEXT
);

\copy staging.stg_crew FROM 'data/crew.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
