-- ============================================================================
-- VISTAS CON FILTROS
-- ============================================================================
-- Las vistas permiten exponer solo una parte de los datos: ciertas columnas,
-- ciertas filas o una versión resumida. Se marcan como security_barrier para
-- evitar que un usuario sin permisos pueda filtrar filas mediante predicados.
--
--   psql -d peliculas -f src/sql/92_views.sql
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- Catálogo público: oculta descripción y enlace de póster.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_movies_public
WITH (security_barrier = true)
AS
SELECT
    m.movie_id,
    m.name,
    m.release_year,
    m.minute,
    m.rating,
    m.tagline
FROM movies m;

-- ----------------------------------------------------------------------------
-- Películas desde el año 2000.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_movies_recent
WITH (security_barrier = true)
AS
SELECT
    m.movie_id,
    m.name,
    m.release_year,
    m.minute,
    m.rating
FROM movies m
WHERE m.release_year >= 2000;

-- ----------------------------------------------------------------------------
-- Estrenos ya ocurridos (excluye fechas futuras).
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_releases_public
WITH (security_barrier = true)
AS
SELECT
    r.movie_id,
    m.name            AS movie_name,
    c.name            AS country,
    r.release_date,
    rt.name           AS release_type,
    ce.name           AS certification
FROM releases r
JOIN movies m          ON m.movie_id = r.movie_id
JOIN countries c       ON c.country_id = r.country_id
JOIN release_types rt  ON rt.release_type_id = r.release_type_id
LEFT JOIN certifications ce
                       ON ce.certification_id = r.certification_id
WHERE r.release_date <= CURRENT_DATE;

-- ----------------------------------------------------------------------------
-- Estrenos anunciados (fechas futuras). Se reserva para analistas y admin.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_releases_upcoming
WITH (security_barrier = true)
AS
SELECT
    r.movie_id,
    m.name            AS movie_name,
    c.name            AS country,
    r.release_date,
    rt.name           AS release_type
FROM releases r
JOIN movies m          ON m.movie_id = r.movie_id
JOIN countries c       ON c.country_id = r.country_id
JOIN release_types rt  ON rt.release_type_id = r.release_type_id
WHERE r.release_date > CURRENT_DATE;

-- ----------------------------------------------------------------------------
-- Reparto en formato legible.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_movie_cast_public
WITH (security_barrier = true)
AS
SELECT
    mc.movie_id,
    m.name AS movie_name,
    p.name AS person_name,
    mc.character_name
FROM movie_cast mc
JOIN movies m ON m.movie_id = mc.movie_id
JOIN people p ON p.person_id = mc.person_id;

COMMIT;
