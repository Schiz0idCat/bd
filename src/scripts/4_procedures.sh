#!/usr/bin/env bash

# ETAPA 4: crea los procedimientos almacenados de los mantenedores.
#
# usa CREATE OR REPLACE PROCEDURE.

set -euo pipefail

cd "$(dirname -- "$0")/../.."

psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/91_procedures.sql
