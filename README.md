# Base de datos de películas — PostgreSQL

Trabajo final de **INF3541-2 Taller de Base de Datos**. Implementa en PostgreSQL
un modelo normalizado de 19 tablas a partir de un catálogo de películas, con
carga en dos capas (staging y traspaso), integridad declarativa, triggers de
auditoría, procedimientos almacenados, consultas optimizadas y control de acceso
por roles.

## Requisitos

- PostgreSQL 14 o superior (probado con PostgreSQL 18).
- `psql`, `createdb`, `dropdb`.
- Bash.
- Los archivos CSV en `data/` con estos nombres:

```
movies.csv  posters.csv  actors.csv   crew.csv      studios.csv
releases.csv  languages.csv  countries.csv  genres.csv  themes.csv
```

## Fuente del dataset

El dataset original ocupa aproximadamente 801 MB y contiene 941.597 películas.
Fue publicado en 2024, por lo que no cumple estrictamente el requisito de
recencia; su uso fue autorizado por el profesor.

Fuente: <https://www.kaggle.com/datasets/gsimonx37/letterboxd>

El directorio `data/posters/` (imágenes, ~24 GB) no es utilizado por el modelo y
no forma parte de la entrega.

## Estructura

```
src/
  sql/
    init.sql              modelo oficial: 19 tablas, constraints e índices
    staging/
      00_schema.sql       crea el schema staging
      01_movies.sql ... 10_releases.sql
                          un archivo por CSV: DDL + \copy
    load/
      00_reset.sql        vacía el modelo para permitir recargas
      01_movies.sql ... 10_releases.sql
                          traspaso staging -> modelo
    90_audit.sql          tabla audit_log, función y triggers
    91_procedures.sql     procedimientos de mantenedores
    92_views.sql          vistas con filtros de filas y columnas
    93_roles.sql          roles y permisos
    94_tests.sql          pruebas de auditoría, procedimientos y permisos
    99_validate.sql       validación de conteos e integridad
    queries/
      00_reset_indexes.sql restaura los índices base
      01_query_where.sql  consulta A (WHERE, OR, IN, sin JOIN)
      02_query_join.sql   consulta B equivalente (JOIN, CTE, EXISTS)
      03_equivalence.sql  verifica que A y B devuelvan lo mismo
      04_indexes.sql      índices de optimización
  scripts/
    db.sh                 crea la base y aplica init.sql
    staging.sh            CSV -> tablas de texto en staging
    load.sh               staging -> modelo + ANALYZE + validación
    objects.sh            auditoría + procedimientos + vistas + roles
    test.sh               pruebas, equivalencia y planes de ejecución
    package.sh            genera el ZIP de entrega
```

## Ejecución

Cada etapa se ejecuta por separado y se puede repetir sin duplicar datos.

```bash
# 1. Crear la base y el modelo (borra la base si ya existe)
./src/scripts/db.sh

# 2. Copiar los CSV a las tablas de texto de staging
./src/scripts/staging.sh

# 3. Traspasar staging al modelo, analizar y validar
./src/scripts/load.sh

# 4. Crear auditoría, procedimientos, vistas y roles
./src/scripts/objects.sh

# 5. Probar los objetos y comparar los planes de las consultas
./src/scripts/test.sh

# 6. Generar el ZIP de entrega
./src/scripts/package.sh
```

Los scripts usan siempre la base `peliculas`. La conexión se configura con las
variables estándar de `psql` (`PGHOST`, `PGPORT`, `PGUSER`).

Cada etapa es idempotente: `staging.sh` recrea el schema, `load.sh` vacía el
modelo antes de cargar, `objects.sh` reemplaza sus objetos y `test.sh` restaura
los índices antes de medir.

### Ejecución parcial

```bash
# Solo staging de un archivo
psql -d peliculas -f src/sql/staging/01_movies.sql

# Solo el traspaso de películas
psql -d peliculas -f src/sql/load/01_movies.sql
```

## Modelo

- `movies` es la tabla principal.
- `people` unifica actores y crew.
- Los catálogos (`countries`, `genres`, `themes`, `studios`, `languages`,
  `language_types`, `crew_roles`, `release_types`, `certifications`) se resuelven
  por nombre.
- Las relaciones N:M son `movie_countries`, `movie_genres`, `movie_themes`,
  `movie_studios`, `movie_languages`, `movie_cast`, `movie_crew` y `releases`.

El detalle del diseño, las decisiones y los planes de ejecución está en
`docs/informe.pdf`.

## Auditoría

`audit_log` guarda la tabla, la operación (`I`, `U`, `D`), la clave de la fila,
los datos anteriores y nuevos en `JSONB`, el usuario y la marca de tiempo. La
tabla es append-only: triggers propios impiden `UPDATE`, `DELETE` y `TRUNCATE`.

Los triggers se crean con `objects.sh`, es decir, **después** de la carga. Si se
crearan antes, registrarían las 941.597 inserciones iniciales.

## Roles

| Rol | Acceso |
|---|---|
| `bd_lectura` | Solo vistas públicas (`vw_movies_public`, `vw_movies_recent`, `vw_releases_public`, `vw_movie_cast_public`) |
| `bd_mantenedor` | `SELECT` + `DML` sobre las tablas mantenidas + ejecución de procedimientos |
| `bd_admin` | Control total |

Los roles son `NOLOGIN`. Para un usuario real:

```sql
CREATE ROLE juan LOGIN PASSWORD '...' IN ROLE bd_lectura;
```

## Notas de carga

- Los CSV se copian con `\copy` a tablas `UNLOGGED` del schema `staging`, sin
  FKs ni constraints.
- El traspaso usa SQL simple: `INSERT ... SELECT`, `CAST`, `NULLIF`, `DISTINCT`
  y `JOIN`.
- Los nombres se conservan exactamente como vienen en el CSV, incluidos los
  espacios Unicode de 33 roles y 22 estudios.
- `99_validate.sql` falla si algún conteo, nulo esperado u huérfano no coincide.
