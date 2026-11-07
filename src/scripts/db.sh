#!/usr/bin/env bash
set -euo pipefail

# Cada ejecución borra la base y la crea de nuevo desde init.sql.

DB_NAME="peliculas"
SCHEMA="$(cd -- "$(dirname -- "$0")" && pwd)/../sql/init.sql"

if psql -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1; then
    echo "Borrando base de datos: '$DB_NAME'..."
    dropdb --force -- "$DB_NAME"
fi

echo "Creando base de datos: '$DB_NAME'..."
createdb -- "$DB_NAME"

echo "Aplicando init.sql..."
PGOPTIONS='-c client_min_messages=warning' \
    psql -q -v ON_ERROR_STOP=1 -d "$DB_NAME" -f "$SCHEMA"

echo "Listo. Conectar: psql -d $DB_NAME"
