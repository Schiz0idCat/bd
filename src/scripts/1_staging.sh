#!/usr/bin/env bash

# carga los CSV en las tablas de texto del schema staging.
#
# 00_schema.sql elimina y recrea el schema completo.

set -euo pipefail

cd "$(dirname -- "$0")/../.."

psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/staging/00_schema.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/staging/01_movies.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/staging/02_posters.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/staging/03_countries.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/staging/04_genres.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/staging/05_themes.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/staging/06_studios.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/staging/07_languages.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/staging/08_actors.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/staging/09_crew.sql
psql -X -v ON_ERROR_STOP=1 -d peliculas -f src/sql/staging/10_releases.sql
