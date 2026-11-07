-- ============================================================================
-- SCHEMA DE TRASPASO (STAGING)
-- ============================================================================
-- Las tablas de este schema son un espejo de los CSV. No tienen FKs, CHECK ni
-- UNIQUE: la limpieza y validación se hacen en los scripts de load/.
-- ============================================================================

DROP SCHEMA IF EXISTS staging CASCADE;
CREATE SCHEMA staging;
