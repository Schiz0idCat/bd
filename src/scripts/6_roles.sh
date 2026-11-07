#!/usr/bin/env bash
#
# crea los roles y asigna los permisos de acceso.
#
# Idempotente: elimina los roles y los vuelve a crear desde cero.
#
#   ./src/scripts/6_roles.sh
# ============================================================================

set -euo pipefail

cd "$(dirname -- "$0")/../.."

psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/93_roles.sql
