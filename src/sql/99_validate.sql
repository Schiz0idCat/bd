-- ============================================================================
-- VALIDACIÓN DE LA CARGA
-- ============================================================================
-- Falla con RAISE EXCEPTION si algún conteo o integridad no coincide con lo
-- esperado para el dataset actual.
-- ============================================================================

DO $$
DECLARE
    r RECORD;
    n BIGINT;
BEGIN
    FOR r IN
        SELECT *
        FROM (VALUES
            ('movies',          941597),
            ('people',         2479949),
            ('movie_cast',     5797504),
            ('movie_crew',     4718901),
            ('releases',       1332782),
            ('movie_countries', 693476),
            ('movie_genres',   1046849),
            ('movie_themes',    125641),
            ('movie_studios',   679071),
            ('movie_languages',1038762),
            ('countries',          247),
            ('genres',              19),
            ('themes',             109),
            ('studios',         160884),
            ('languages',          192),
            ('language_types',       3),
            ('crew_roles',          29),
            ('release_types',        6),
            ('certifications',     286)
        ) AS t(tbl, expected)
    LOOP
        EXECUTE format('SELECT count(*) FROM %I', r.tbl) INTO n;
        IF n <> r.expected THEN
            RAISE EXCEPTION 'Tabla %: esperado %, obtenido %',
                r.tbl, r.expected, n;
        END IF;
    END LOOP;
END $$;

DO $$
DECLARE
    n BIGINT;
BEGIN
    SELECT count(*) INTO n FROM movies WHERE poster_link = '';
    IF n <> 0 THEN
        RAISE EXCEPTION 'movies.poster_link contiene % cadenas vacías', n;
    END IF;

    SELECT count(*) INTO n FROM movies WHERE poster_link IS NULL;
    IF n <> 180712 THEN
        RAISE EXCEPTION 'movies.poster_link NULL: esperado 180712, obtenido %', n;
    END IF;

    SELECT count(*) INTO n FROM movies WHERE release_year IS NULL;
    IF n <> 91913 THEN
        RAISE EXCEPTION 'movies.release_year NULL: esperado 91913, obtenido %', n;
    END IF;

    SELECT count(*) INTO n FROM movies WHERE minute IS NULL;
    IF n <> 181570 THEN
        RAISE EXCEPTION 'movies.minute NULL: esperado 181570, obtenido %', n;
    END IF;

    SELECT count(*) INTO n FROM movies WHERE rating IS NULL;
    IF n <> 850598 THEN
        RAISE EXCEPTION 'movies.rating NULL: esperado 850598, obtenido %', n;
    END IF;

    SELECT count(*) INTO n FROM movies WHERE tagline IS NULL;
    IF n <> 802193 THEN
        RAISE EXCEPTION 'movies.tagline NULL: esperado 802193, obtenido %', n;
    END IF;

    SELECT count(*) INTO n FROM movies WHERE description IS NULL;
    IF n <> 160810 THEN
        RAISE EXCEPTION 'movies.description NULL: esperado 160810, obtenido %', n;
    END IF;

    SELECT count(*) INTO n FROM movie_cast WHERE character_name IS NULL;
    IF n <> 1361098 THEN
        RAISE EXCEPTION 'movie_cast.character_name NULL: esperado 1361098, obtenido %', n;
    END IF;

    SELECT count(*) INTO n FROM releases WHERE certification_id IS NULL;
    IF n <> 998782 THEN
        RAISE EXCEPTION 'releases.certification_id NULL: esperado 998782, obtenido %', n;
    END IF;
END $$;

DO $$
DECLARE
    r RECORD;
    n BIGINT;
BEGIN
    FOR r IN
        SELECT unnest(ARRAY[
            'movie_countries',
            'movie_genres',
            'movie_themes',
            'movie_studios',
            'movie_languages',
            'movie_cast',
            'movie_crew',
            'releases'
        ]) AS tbl
    LOOP
        EXECUTE format(
            'SELECT count(*) FROM %I x
             WHERE NOT EXISTS (
                 SELECT 1 FROM movies m WHERE m.movie_id = x.movie_id
             )',
            r.tbl
        ) INTO n;
        IF n <> 0 THEN
            RAISE EXCEPTION 'Tabla %: % filas huérfanas', r.tbl, n;
        END IF;
    END LOOP;
END $$;

SELECT 'Validación OK' AS resultado;
