-- Pasar languages.csv a language_types, languages y movie_languages.

BEGIN;

INSERT INTO language_types (name)
SELECT DISTINCT type
FROM staging.stg_languages;

INSERT INTO languages (name)
SELECT DISTINCT language
FROM staging.stg_languages;

INSERT INTO movie_languages (movie_id, language_id, language_type_id)
SELECT DISTINCT s.id, l.language_id, t.language_type_id
FROM staging.stg_languages s
JOIN languages l ON l.name = s.language
JOIN language_types t ON t.name = s.type;

COMMIT;
