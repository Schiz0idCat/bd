-- Las tablas de este schema son un espejo de los CSV.
-- No tienen ninguna lógica compleja SQL más allá de la misma definición de las tablas.

DROP SCHEMA IF EXISTS staging CASCADE; -- pata idempotencia.
CREATE SCHEMA staging;
