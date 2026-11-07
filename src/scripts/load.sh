#!/usr/bin/env bash
# ============================================================================
# ETAPA 2: traspasa staging al modelo real.
#
# Idempotente: 00_reset.sql vacía el modelo antes de cada carga.
#
#   ./src/scripts/load.sh
# ============================================================================

set -euo pipefail

cd "$(dirname -- "$0")/../.."

psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/load/00_reset.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/load/01_movies.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/load/02_countries.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/load/03_genres.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/load/04_themes.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/load/05_studios.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/load/06_languages.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/load/07_people.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/load/08_cast.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/load/09_crew.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/load/10_releases.sql

psql -X -v ON_ERROR_STOP=1 -d peliculas -c "ANALYZE;"
