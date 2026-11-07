#!/usr/bin/env bash
# ============================================================================
# ETAPA 3: crea la tabla de auditoría, la función y los triggers de log.
#
# Idempotente: el script elimina la tabla y los triggers antes de crearlos.
#
#   ./src/scripts/triggers.sh
# ============================================================================

set -euo pipefail

cd "$(dirname -- "$0")/../.."

psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/90_audit.sql
