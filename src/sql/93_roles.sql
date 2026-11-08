BEGIN;

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

-- Nadie crea elementos, salvo el administrador
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO bd_lectura, bd_mantenedor, bd_admin;
GRANT CREATE ON SCHEMA public TO bd_admin;

-- Se parte de cero
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL PROCEDURES IN SCHEMA public FROM PUBLIC;

-- Las funciones de trigger no se ejecutan directamente
REVOKE ALL ON FUNCTION fn_audit_row() FROM PUBLIC;
REVOKE ALL ON FUNCTION fn_audit_log_immutable() FROM PUBLIC;

-- bd_lectura: solo vistas con filtros
GRANT SELECT ON
    vw_movies_public,
    vw_releases_public
TO bd_lectura;

-- bd_mantenedor: mantenedores a través de procedimientos
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
