#!/usr/bin/env bash
# ============================================================================
# ETAPA 5: crea las vistas con filtros de filas y columnas.
#
# Idempotente: usa CREATE OR REPLACE VIEW.
#
#   ./src/scripts/5_views.sh
# ============================================================================

set -euo pipefail

cd "$(dirname -- "$0")/../.."

psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/92_views.sql
