-- actors.csv

DROP TABLE IF EXISTS staging.stg_actors;

CREATE UNLOGGED TABLE staging.stg_actors (
    id   INTEGER,
    name TEXT,
    role TEXT
);

\copy staging.stg_actors FROM 'data/actors.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
