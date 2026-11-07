#!/usr/bin/env bash
# ============================================================================
# ETAPA 3: instala los objetos sobre el modelo ya cargado.
#
# Cada script SQL es idempotente, por lo que este script se puede repetir.
# Debe ejecutarse DESPUÉS de load.sh para que los triggers de auditoría no
# registren las inserciones masivas.
#
#   ./src/scripts/objects.sh
# ============================================================================

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$ROOT"

DB="peliculas"
PSQL=(psql -X -v ON_ERROR_STOP=1 -d "$DB")

echo "==> Triggers de auditoría"
"${PSQL[@]}" -f src/sql/90_audit.sql

echo "==> Procedimientos almacenados"
"${PSQL[@]}" -f src/sql/91_procedures.sql

echo "==> Vistas"
"${PSQL[@]}" -f src/sql/92_views.sql

echo "==> Roles y permisos"
"${PSQL[@]}" -f src/sql/93_roles.sql

echo "==> Objetos instalados."
