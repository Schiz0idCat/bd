#!/usr/bin/env bash
# ============================================================================
# ETAPA 6: crea los roles y asigna los permisos de acceso.
#
# Idempotente: crea los roles solo si no existen y vuelve a aplicar los GRANT.
#
#   ./src/scripts/roles.sh
# ============================================================================

set -euo pipefail

cd "$(dirname -- "$0")/../.."

psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/93_roles.sql
