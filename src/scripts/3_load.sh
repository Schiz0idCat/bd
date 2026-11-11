#!/usr/bin/env bash

# traspasa staging al modelo real.
#
# 00_reset.sql vacía el modelo antes de cada carga.
#
# Los triggers de auditoría se desactivan durante la carga para no registrar
# millones de inserciones. Si la carga falla, el trap los vuelve a activar.

set -euo pipefail

cd "$(dirname -- "$0")/../.."

habilitar_triggers() {
    psql -X -v ON_ERROR_STOP=1 -d peliculas -c "
        ALTER TABLE movies   ENABLE TRIGGER USER;
        ALTER TABLE people   ENABLE TRIGGER USER;
        ALTER TABLE studios  ENABLE TRIGGER USER;
        ALTER TABLE releases ENABLE TRIGGER USER;
    " >/dev/null 2>&1 || true
}

trap habilitar_triggers EXIT

psql -X -v ON_ERROR_STOP=1 -d peliculas -c "
    ALTER TABLE movies   DISABLE TRIGGER USER;
    ALTER TABLE people   DISABLE TRIGGER USER;
    ALTER TABLE studios  DISABLE TRIGGER USER;
    ALTER TABLE releases DISABLE TRIGGER USER;
"

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
