-- Pasar themes.csv a themes y movie_themes.

BEGIN;

INSERT INTO themes (name)
SELECT DISTINCT theme
FROM staging.stg_themes;

INSERT INTO movie_themes (movie_id, theme_id)
SELECT DISTINCT s.id, t.theme_id
FROM staging.stg_themes s
JOIN themes t ON t.name = s.theme;

COMMIT;
