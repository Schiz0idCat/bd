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
--   bd_mantenedor  -> DML mínimo para los procedimientos de mantenimiento
--   bd_admin       -> acceso total de lectura/escritura y ejecución
--
--   psql -d peliculas -f src/sql/93_roles.sql
-- ============================================================================

BEGIN;

-- Revocar membresías para poder eliminar los roles aunque existan usuarios
-- LOGIN creados a partir de ellos.
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT miembro.rolname AS miembro, otorgado.rolname AS otorgado
        FROM pg_auth_members am
        JOIN pg_roles miembro  ON miembro.oid = am.member
        JOIN pg_roles otorgado ON otorgado.oid = am.roleid
        WHERE otorgado.rolname IN ('bd_lectura', 'bd_mantenedor', 'bd_admin')
    LOOP
        EXECUTE format('REVOKE %I FROM %I', r.otorgado, r.miembro);
    END LOOP;
END $$;

-- Reasignar los objetos que pertenezcan a los roles (para no borrarlos) y
-- revocar todos sus privilegios antes de eliminarlos.
DO $$
DECLARE
    r TEXT;
BEGIN
    FOREACH r IN ARRAY ARRAY['bd_lectura', 'bd_mantenedor', 'bd_admin'] LOOP
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
            EXECUTE format('REASSIGN OWNED BY %I TO %I', r, current_user);
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

-- Las funciones de trigger no se ejecutan directamente.
REVOKE ALL ON FUNCTION fn_audit_row() FROM PUBLIC;
REVOKE ALL ON FUNCTION fn_audit_log_immutable() FROM PUBLIC;

-- ----------------------------------------------------------------------------
-- bd_lectura: solo vistas con filtros
-- ----------------------------------------------------------------------------

GRANT SELECT ON
    vw_movies_public,
    vw_releases_public
TO bd_lectura;

-- ----------------------------------------------------------------------------
-- bd_mantenedor: lectura general y DML mínimo para sus procedimientos
-- ----------------------------------------------------------------------------
-- sp_movie_upsert  -> INSERT, UPDATE en movies
-- sp_studio_delete -> DELETE en studios y SELECT en movie_studios
--
-- No se conceden secuencias porque los procedimientos no insertan en tablas
-- con columnas IDENTITY.

GRANT SELECT ON ALL TABLES IN SCHEMA public TO bd_mantenedor;
GRANT INSERT, UPDATE ON movies TO bd_mantenedor;
GRANT DELETE ON studios TO bd_mantenedor;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO bd_mantenedor;

-- El log de auditoría no es parte del acceso del mantenedor.
DO $$
BEGIN
    IF to_regclass('public.audit_log') IS NOT NULL THEN
        REVOKE SELECT ON audit_log FROM bd_mantenedor;
    END IF;
END $$;

-- ----------------------------------------------------------------------------
-- bd_admin: acceso total de datos y ejecución
-- ----------------------------------------------------------------------------

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO bd_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO bd_admin;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO bd_admin;

-- El log es append-only: el administrador solo puede leerlo. La función de
-- auditoría es SECURITY DEFINER y se encarga de insertar.
DO $$
BEGIN
    IF to_regclass('public.audit_log') IS NOT NULL THEN
        REVOKE ALL PRIVILEGES ON audit_log FROM bd_admin;
        GRANT SELECT ON audit_log TO bd_admin;
    END IF;
END $$;

COMMIT;
