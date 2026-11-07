#!/usr/bin/env bash
# ============================================================================
# Pruebas de objetos y comparación de planes de ejecución.
#
#   ./src/scripts/test.sh
#
# Guarda los planes en docs/build/ (ignorado por git) y los muestra en
# pantalla. Requiere haber ejecutado db.sh, load.sh y objects.sh.
# ============================================================================

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$ROOT"

DB="${PGDATABASE:-peliculas}"
PSQL=(psql -X -v ON_ERROR_STOP=1 -d "$DB")
OUT="$ROOT/docs/build"
mkdir -p "$OUT"

run_plan() {
    local etiqueta="$1"
    local archivo="$2"
    local destino="$3"

    {
        echo "-- ============================================================"
        echo "-- $etiqueta"
        echo "-- ============================================================"
        echo "EXPLAIN (ANALYZE, BUFFERS, TIMING OFF)"
        cat "$archivo"
    } | psql -X -v ON_ERROR_STOP=1 -d "$DB" | tee "$destino"
}

echo "==> Restaurando índices base"
"${PSQL[@]}" -f src/sql/queries/00_reset_indexes.sql >/dev/null

echo "==> Pruebas de auditoría, procedimientos y permisos"
"${PSQL[@]}" -f src/sql/94_tests.sql

echo "==> Equivalencia de consultas"
"${PSQL[@]}" -f src/sql/queries/03_equivalence.sql

echo "==> Planes ANTES de los índices"
run_plan "CONSULTA A (WHERE, OR, IN)" \
    src/sql/queries/01_query_where.sql "$OUT/plan_a_antes.txt"
run_plan "CONSULTA B (JOIN, CTE, EXISTS)" \
    src/sql/queries/02_query_join.sql "$OUT/plan_b_antes.txt"

echo "==> Creando índices de optimización"
"${PSQL[@]}" -f src/sql/queries/04_indexes.sql >/dev/null

echo "==> Planes DESPUÉS de los índices"
run_plan "CONSULTA A (WHERE, OR, IN)" \
    src/sql/queries/01_query_where.sql "$OUT/plan_a_despues.txt"
run_plan "CONSULTA B (JOIN, CTE, EXISTS)" \
    src/sql/queries/02_query_join.sql "$OUT/plan_b_despues.txt"

echo "==> Fin."
