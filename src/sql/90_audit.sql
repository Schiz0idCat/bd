-- Este script se aplica DESPUÉS de la carga inicial.
-- Genera la tabla de auditoría.

BEGIN;

DROP TABLE IF EXISTS audit_log CASCADE;

CREATE TABLE audit_log (
    audit_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name  TEXT        NOT NULL,
    operation   CHAR(1)     NOT NULL,
    row_key     JSONB       NOT NULL,
    old_data    JSONB,
    new_data    JSONB,
    db_user     NAME        NOT NULL DEFAULT session_user,
    changed_at  TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT audit_log_operation_valid CHECK (operation IN ('I', 'U', 'D'))
);

CREATE INDEX idx_audit_log_table_time
    ON audit_log (table_name, changed_at DESC);
CREATE INDEX idx_audit_log_user
    ON audit_log (db_user, changed_at DESC);

-- Función genérica de auditoría
-- 
-- TG_ARGV recibe los nombres de las columnas que forman la clave primaria de la tabla auditada.
-- Así la misma función sirve para claves simples y compuestas.

CREATE OR REPLACE FUNCTION fn_audit_row()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_old   JSONB;
    v_new   JSONB;
    v_row   JSONB;
    v_key   JSONB := '{}'::JSONB;
    v_col   TEXT;
BEGIN
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        v_old := to_jsonb(OLD);
    END IF;
    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        v_new := to_jsonb(NEW);
    END IF;

    v_row := COALESCE(v_new, v_old);

    FOREACH v_col IN ARRAY TG_ARGV LOOP
        v_key := v_key || jsonb_build_object(v_col, v_row -> v_col);
    END LOOP;

    INSERT INTO audit_log (table_name, operation, row_key, old_data, new_data)
    VALUES (TG_TABLE_NAME, substring(TG_OP FROM 1 FOR 1), v_key, v_old, v_new);

    RETURN NULL;
END;
$$;

-- Inmutabilidad del log

CREATE OR REPLACE FUNCTION fn_audit_log_immutable()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'audit_log es append-only: no se permite % sobre el log',
        TG_OP
        USING ERRCODE = 'insufficient_privilege';
END;
$$;

CREATE TRIGGER trg_audit_log_immutable
    BEFORE UPDATE OR DELETE ON audit_log
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_log_immutable();

CREATE TRIGGER trg_audit_log_no_truncate
    BEFORE TRUNCATE ON audit_log
    FOR EACH STATEMENT
    EXECUTE FUNCTION fn_audit_log_immutable();

-- Triggers sobre las tablas principales

-- Se eliminan primero para que el script se pueda ejecutar más de una vez.
DROP TRIGGER IF EXISTS trg_audit_movies   ON movies;
DROP TRIGGER IF EXISTS trg_audit_people   ON people;
DROP TRIGGER IF EXISTS trg_audit_studios  ON studios;
DROP TRIGGER IF EXISTS trg_audit_releases ON releases;

CREATE TRIGGER trg_audit_movies
    AFTER INSERT OR UPDATE OR DELETE ON movies
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_row('movie_id');

CREATE TRIGGER trg_audit_people
    AFTER INSERT OR UPDATE OR DELETE ON people
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_row('person_id');

CREATE TRIGGER trg_audit_studios
    AFTER INSERT OR UPDATE OR DELETE ON studios
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_row('studio_id');

CREATE TRIGGER trg_audit_releases
    AFTER INSERT OR UPDATE OR DELETE ON releases
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_row(
        'movie_id', 'country_id', 'release_date', 'release_type_id'
    );

COMMIT;
