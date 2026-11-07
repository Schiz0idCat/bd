#!/usr/bin/env bash
# ============================================================================
# Carga completa del dataset.
#
# Requisitos:
#   1. La base de datos debe existir y tener aplicado src/sql/init.sql.
#      Eso lo hace src/scripts/db.sh.
#   2. Los CSV deben estar en data/.
#
# Uso:
#   ./src/scripts/db.sh
#   ./src/scripts/load.sh
#
# Variables opcionales:
#   PGDATABASE       nombre de la base (por defecto: peliculas)
#   DROP_STAGING=1   elimina el schema staging al terminar
# ============================================================================

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$ROOT"

DB="${PGDATABASE:-peliculas}"
PSQL=(psql -X -v ON_ERROR_STOP=1 -d "$DB")

if ! command -v psql >/dev/null 2>&1; then
    echo "Error: no se encontró psql." >&2
    exit 1
fi

if ! "${PSQL[@]}" -tAc "SELECT to_regclass('public.movies')" | grep -q movies; then
    echo "Error: la base '$DB' no existe o no tiene el esquema aplicado." >&2
    echo "Ejecuta primero: ./src/scripts/db.sh" >&2
    exit 1
fi

echo "==> Creando schema staging"
"${PSQL[@]}" -f src/sql/staging/00_schema.sql

echo "==> Copiando CSV a staging"
for f in src/sql/staging/[0-9][0-9]_*.sql; do
    [[ "$f" == *"/00_schema.sql" ]] && continue
    echo "    $(basename "$f")"
    "${PSQL[@]}" -f "$f"
done

echo "==> Traspasando staging -> modelo"
for f in src/sql/load/[0-9][0-9]_*.sql; do
    echo "    $(basename "$f")"
    "${PSQL[@]}" -f "$f"
done

echo "==> Analizando tablas"
"${PSQL[@]}" -c "ANALYZE;"

echo "==> Validando carga"
"${PSQL[@]}" -f src/sql/99_validate.sql

if [[ "${DROP_STAGING:-0}" == "1" ]]; then
    echo "==> Eliminando schema staging"
    "${PSQL[@]}" -c "DROP SCHEMA staging CASCADE;"
fi

echo "Carga completada."
