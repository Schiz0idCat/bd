#!/usr/bin/env bash

# ETAPA 1: CSV -> tablas de texto del schema staging.
#
# Idempotente: 00_schema.sql elimina y recrea el schema completo, y cada
# archivo de staging elimina su tabla antes de crearla y copiar el CSV.
#
#   ./src/scripts/staging.sh
# ============================================================================

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$ROOT"

DB="peliculas"
PSQL=(psql -X -v ON_ERROR_STOP=1 -d "$DB")

if ! "${PSQL[@]}" -tAc "SELECT to_regclass('public.movies')" | grep -q movies; then
    echo "Error: la base '$DB' no existe o no tiene el modelo." >&2
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

echo "==> Staging completo."
