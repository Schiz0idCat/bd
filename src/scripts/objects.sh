#!/usr/bin/env bash
# ============================================================================
# Instala los objetos de la base: auditoría, procedimientos, vistas y roles.
#
# Debe ejecutarse DESPUÉS de cargar los datos, para que los triggers de
# auditoría no registren las 941.597 inserciones de la carga masiva.
#
# Uso:
#   ./src/scripts/objects.sh
#
# Variables opcionales:
#   PGDATABASE    nombre de la base (por defecto: peliculas)
#   SKIP_ROLES=1  no crea los roles (útil si no se es superusuario)
# ============================================================================

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$ROOT"

DB="${PGDATABASE:-peliculas}"
PSQL=(psql -X -v ON_ERROR_STOP=1 -d "$DB")

echo "==> Triggers de auditoría"
"${PSQL[@]}" -f src/sql/90_audit.sql

echo "==> Procedimientos almacenados"
"${PSQL[@]}" -f src/sql/91_procedures.sql

echo "==> Vistas"
"${PSQL[@]}" -f src/sql/92_views.sql

if [[ "${SKIP_ROLES:-0}" == "1" ]]; then
    echo "==> Roles omitidos (SKIP_ROLES=1)"
else
    echo "==> Roles y permisos"
    "${PSQL[@]}" -f src/sql/93_roles.sql
fi

echo "==> Objetos instalados."
