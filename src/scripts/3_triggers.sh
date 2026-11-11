#!/usr/bin/env bash

# crea la tabla de auditoría, la función y los triggers de log.
#
# Conserva audit_log si ya existe y recrea sus triggers.

set -euo pipefail

cd "$(dirname -- "$0")/../.."

psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/90_audit.sql
