-- Deja el modelo vacío para que la carga se pueda repetir sin duplicar datos.
-- Se incluyen todas las tablas para no depender de CASCADE entre ellas.

BEGIN;

TRUNCATE TABLE
    movie_cast,
    movie_crew,
    movie_languages,
    movie_genres,
    movie_themes,
    movie_countries,
    movie_studios,
    releases,
    movies,
    people,
    studios,
    themes,
    genres,
    countries,
    languages,
    language_types,
    crew_roles,
    release_types,
    certifications
RESTART IDENTITY CASCADE;

COMMIT;
