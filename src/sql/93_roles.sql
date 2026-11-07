-- ============================================================================
-- USUARIOS, PERMISOS Y NIVELES DE ACCESO
-- ============================================================================
-- Se crean roles sin login (NOLOGIN). Para cada usuario real se crea un rol
-- con LOGIN y se le asigna uno de estos roles:
--
--     CREATE ROLE juan LOGIN PASSWORD '...' IN ROLE bd_lectura;
--
-- Niveles:
--   bd_lectura     -> solo vistas públicas (columnas y filas filtradas)
--   bd_mantenedor  -> ejecuta los procedimientos de mantenimiento
--   bd_admin       -> control total
--
--   psql -d peliculas -f src/sql/93_roles.sql
-- ============================================================================

BEGIN;

-- Se eliminan y recrean para que el script siempre parta del mismo estado.
-- DROP OWNED BY revoca los privilegios que tengan sobre los objetos.
DO $$
DECLARE
    r TEXT;
BEGIN
    FOREACH r IN ARRAY ARRAY['bd_lectura', 'bd_mantenedor', 'bd_admin'] LOOP
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
            EXECUTE format('DROP OWNED BY %I', r);
        END IF;
    END LOOP;
END $$;

DROP ROLE IF EXISTS bd_admin;
DROP ROLE IF EXISTS bd_mantenedor;
DROP ROLE IF EXISTS bd_lectura;

CREATE ROLE bd_lectura NOLOGIN;
CREATE ROLE bd_mantenedor NOLOGIN;
CREATE ROLE bd_admin NOLOGIN;

-- ----------------------------------------------------------------------------
-- Esquema: nadie crea objetos salvo el administrador
-- ----------------------------------------------------------------------------

REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO bd_lectura, bd_mantenedor, bd_admin;
GRANT CREATE ON SCHEMA public TO bd_admin;

-- ----------------------------------------------------------------------------
-- Privilegios por defecto: se parte de cero
-- ----------------------------------------------------------------------------

REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL PROCEDURES IN SCHEMA public FROM PUBLIC;

-- Las funciones de trigger no se ejecutan directamente: solo desde el trigger.
REVOKE ALL ON FUNCTION fn_audit_row() FROM PUBLIC;
REVOKE ALL ON FUNCTION fn_audit_log_immutable() FROM PUBLIC;

-- ----------------------------------------------------------------------------
-- bd_lectura: solo vistas con filtros
-- ----------------------------------------------------------------------------

GRANT SELECT ON
    vw_movies_public,
    vw_movies_recent,
    vw_releases_public,
    vw_movie_cast_public
TO bd_lectura;

-- ----------------------------------------------------------------------------
-- bd_mantenedor: mantenedores a través de procedimientos
-- ----------------------------------------------------------------------------
-- Los procedimientos no son SECURITY DEFINER (lo que permite usar COMMIT y
-- ROLLBACK dentro de ellos), por lo que el rol necesita los privilegios DML
-- sobre las tablas que manipulan y USAGE sobre sus secuencias.

GRANT SELECT ON ALL TABLES IN SCHEMA public TO bd_mantenedor;
GRANT INSERT, UPDATE, DELETE ON
    movies,
    people,
    studios,
    releases,
    countries,
    release_types,
    certifications,
    movie_cast,
    movie_crew
TO bd_mantenedor;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO bd_mantenedor;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO bd_mantenedor;

-- ----------------------------------------------------------------------------
-- bd_admin: control total
-- ----------------------------------------------------------------------------

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO bd_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO bd_admin;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO bd_admin;
-- Necesario para que los triggers de auditoría puedan dispararse en sus DML.
GRANT EXECUTE ON FUNCTION fn_audit_row() TO bd_admin;

-- El log es append-only incluso para el administrador: los triggers lo
-- impiden a nivel de fila. Solo el dueño del esquema puede deshabilitarlos.

COMMIT;
