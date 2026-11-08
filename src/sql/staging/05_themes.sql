-- themes.csv

DROP TABLE IF EXISTS staging.stg_themes;

CREATE UNLOGGED TABLE staging.stg_themes (
    id    INTEGER,
    theme TEXT
);

\copy staging.stg_themes FROM 'data/themes.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')
