BEGIN;

-- Asegura idempotencia (con propósitos de testeo)
DROP TABLE IF EXISTS
    movie_cast,
    movie_crew,
    movie_languages,
    movie_genres,
    movie_themes,
    movie_countries,
    movie_studios,
    releases,
    posters,
    movies,
    people,
    studios,
    themes,
    genres,
    countries,
    languages,
    language_types,
    crew_roles,
    release_types
CASCADE;

-- ============================================================================
-- PELÍCULAS
-- ============================================================================

CREATE TABLE movies (
    movie_id        INTEGER       PRIMARY KEY,
    name            VARCHAR(255)  NOT NULL,
    release_year    SMALLINT,
    tagline         VARCHAR(255),
    description     TEXT,
    minute          INTEGER,
    rating          NUMERIC(3,2),

    CONSTRAINT movies_name_not_blank  CHECK (btrim(name) <> ''),
    CONSTRAINT movies_year_range      CHECK (release_year BETWEEN 1870 AND 2100),
    CONSTRAINT movies_minute_positive CHECK (minute > 0),
    CONSTRAINT movies_rating_range    CHECK (rating BETWEEN 0 AND 5)
);

CREATE TABLE posters (
    movie_id INTEGER PRIMARY KEY
        REFERENCES movies(movie_id) ON DELETE CASCADE,
    link     TEXT,

    CONSTRAINT posters_link_not_blank
        CHECK (link IS NULL OR btrim(link) <> '')
);

-- ============================================================================
-- CATÁLOGOS
-- ============================================================================

CREATE TABLE countries (
    country_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE genres (
    genre_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name     VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE themes (
    theme_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name     VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE studios (
    studio_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name      VARCHAR(200) NOT NULL UNIQUE
);

CREATE TABLE language_types (
    language_type_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name             VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE languages (
    language_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE crew_roles (
    crew_role_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name         VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE release_types (
    release_type_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            VARCHAR(50) NOT NULL UNIQUE
);

-- ============================================================================
-- PERSONAS
-- ============================================================================

CREATE TABLE people (
    person_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name      VARCHAR(255) NOT NULL UNIQUE
);

-- ============================================================================
-- RELACIONES PELÍCULA - CATÁLOGO
-- ============================================================================

CREATE TABLE movie_countries (
    movie_id   INTEGER  NOT NULL
        REFERENCES movies(movie_id) ON DELETE CASCADE,
    country_id SMALLINT NOT NULL
        REFERENCES countries(country_id),
    PRIMARY KEY (movie_id, country_id)
);

CREATE INDEX idx_movie_countries_country
    ON movie_countries (country_id);

CREATE TABLE movie_genres (
    movie_id INTEGER  NOT NULL
        REFERENCES movies(movie_id) ON DELETE CASCADE,
    genre_id SMALLINT NOT NULL
        REFERENCES genres(genre_id),
    PRIMARY KEY (movie_id, genre_id)
);

CREATE INDEX idx_movie_genres_genre
    ON movie_genres (genre_id);

CREATE TABLE movie_themes (
    movie_id INTEGER  NOT NULL
        REFERENCES movies(movie_id) ON DELETE CASCADE,
    theme_id SMALLINT NOT NULL
        REFERENCES themes(theme_id),
    PRIMARY KEY (movie_id, theme_id)
);

CREATE INDEX idx_movie_themes_theme
    ON movie_themes (theme_id);

CREATE TABLE movie_studios (
    movie_id  INTEGER NOT NULL
        REFERENCES movies(movie_id) ON DELETE CASCADE,
    studio_id INTEGER NOT NULL
        REFERENCES studios(studio_id),
    PRIMARY KEY (movie_id, studio_id)
);

CREATE INDEX idx_movie_studios_studio
    ON movie_studios (studio_id);

CREATE TABLE movie_languages (
    movie_id         INTEGER  NOT NULL
        REFERENCES movies(movie_id) ON DELETE CASCADE,
    language_id      SMALLINT NOT NULL
        REFERENCES languages(language_id),
    language_type_id SMALLINT NOT NULL
        REFERENCES language_types(language_type_id),
    PRIMARY KEY (movie_id, language_id, language_type_id)
);

CREATE INDEX idx_movie_languages_language
    ON movie_languages (language_id);
CREATE INDEX idx_movie_languages_type
    ON movie_languages (language_type_id);

-- ============================================================================
-- REPARTO Y EQUIPO TÉCNICO
-- ============================================================================

CREATE TABLE movie_cast (
    cast_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    movie_id       INTEGER NOT NULL
        REFERENCES movies(movie_id) ON DELETE CASCADE,
    person_id      BIGINT  NOT NULL
        REFERENCES people(person_id),
    character_name VARCHAR(255)
);

CREATE UNIQUE INDEX uq_movie_cast_character
    ON movie_cast (movie_id, person_id, character_name)
    WHERE character_name IS NOT NULL;

CREATE UNIQUE INDEX uq_movie_cast_no_character
    ON movie_cast (movie_id, person_id)
    WHERE character_name IS NULL;

CREATE INDEX idx_movie_cast_movie
    ON movie_cast (movie_id);
CREATE INDEX idx_movie_cast_person
    ON movie_cast (person_id);

CREATE TABLE movie_crew (
    movie_id     INTEGER  NOT NULL
        REFERENCES movies(movie_id) ON DELETE CASCADE,
    person_id    BIGINT   NOT NULL
        REFERENCES people(person_id),
    crew_role_id SMALLINT NOT NULL
        REFERENCES crew_roles(crew_role_id),
    PRIMARY KEY (movie_id, person_id, crew_role_id)
);

CREATE INDEX idx_movie_crew_person
    ON movie_crew (person_id);
CREATE INDEX idx_movie_crew_role
    ON movie_crew (crew_role_id);

-- ============================================================================
-- ESTRENOS
-- ============================================================================

CREATE TABLE releases (
    movie_id        INTEGER  NOT NULL
        REFERENCES movies(movie_id) ON DELETE CASCADE,
    country_id      SMALLINT NOT NULL
        REFERENCES countries(country_id),
    release_date    DATE     NOT NULL,
    release_type_id SMALLINT NOT NULL
        REFERENCES release_types(release_type_id),
    rating          VARCHAR(10), -- TODO: Esto debería ser una tabla aparte, falta normalizar

    PRIMARY KEY (movie_id, country_id, release_date, release_type_id),

    CONSTRAINT releases_date_range
        CHECK (release_date BETWEEN DATE '1870-01-01' AND DATE '2100-12-31'),
    CONSTRAINT releases_rating_not_blank
        CHECK (rating IS NULL OR btrim(rating) <> '')
);

CREATE INDEX idx_releases_country
    ON releases (country_id);
CREATE INDEX idx_releases_date
    ON releases (release_date);
CREATE INDEX idx_releases_type
    ON releases (release_type_id);

-- ============================================================================
-- ÍNDICES DE CONSULTA SOBRE PELÍCULAS
-- ============================================================================

CREATE INDEX idx_movies_release_year
    ON movies (release_year);
CREATE INDEX idx_movies_rating
    ON movies (rating);
CREATE INDEX idx_movies_name
    ON movies (name);

COMMIT;
