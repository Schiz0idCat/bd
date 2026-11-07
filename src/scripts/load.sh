#!/usr/bin/env bash
# ============================================================================
# ETAPA 2: staging -> modelo real.
#
# Idempotente: 00_reset.sql vacía el modelo antes de cada carga.
#
#   ./src/scripts/load.sh
# ============================================================================

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$ROOT"

DB="peliculas"
PSQL=(psql -X -v ON_ERROR_STOP=1 -d "$DB")

if ! "${PSQL[@]}" -tAc "SELECT to_regclass('staging.stg_movies')" | grep -q stg_movies; then
    echo "Error: no existe el schema staging." >&2
    echo "Ejecuta primero: ./src/scripts/staging.sh" >&2
    exit 1
fi

echo "==> Vaciando modelo"
"${PSQL[@]}" -f src/sql/load/00_reset.sql

echo "==> Traspasando staging -> modelo"
for f in src/sql/load/[0-9][0-9]_*.sql; do
    [[ "$f" == *"/00_reset.sql" ]] && continue
    echo "    $(basename "$f")"
    "${PSQL[@]}" -f "$f"
done

echo "==> Analizando tablas"
"${PSQL[@]}" -c "ANALYZE;"

echo "==> Validando carga"
"${PSQL[@]}" -f src/sql/99_validate.sql

echo "==> Carga completa."
