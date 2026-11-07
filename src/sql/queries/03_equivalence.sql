-- ============================================================================
-- VERIFICACIÓN DE EQUIVALENCIA ENTRE LAS CONSULTAS A Y B
-- ============================================================================
-- Ambas diferencias deben dar 0 filas. Si alguna devuelve filas, las consultas
-- no son equivalentes.
-- ============================================================================

WITH a AS (
    SELECT DISTINCT m.movie_id, m.name, m.release_year, m.rating
    FROM movies m, movie_genres mg, genres g,
         movie_countries mc, countries c
    WHERE m.movie_id = mg.movie_id
      AND mg.genre_id = g.genre_id
      AND m.movie_id = mc.movie_id
      AND mc.country_id = c.country_id
      AND (g.name = 'Drama' OR g.name = 'Comedy')
      AND c.name IN ('United States of America')
      AND m.release_year BETWEEN 2000 AND 2009
      AND m.rating >= 4.0
),
b AS (
    SELECT DISTINCT b.movie_id, b.name, b.release_year, b.rating
    FROM (
        SELECT movie_id, name, release_year, rating
        FROM movies
        WHERE release_year BETWEEN 2000 AND 2009
          AND rating >= 4.0
    ) b
    JOIN movie_genres mg ON mg.movie_id = b.movie_id
    JOIN genres g        ON g.genre_id = mg.genre_id
    WHERE g.name IN ('Drama', 'Comedy')
      AND EXISTS (
          SELECT 1
          FROM movie_countries mc
          JOIN countries c ON c.country_id = mc.country_id
          WHERE mc.movie_id = b.movie_id
            AND c.name = 'United States of America'
      )
)
SELECT
    (SELECT count(*) FROM (SELECT * FROM a EXCEPT SELECT * FROM b) x) AS solo_en_a,
    (SELECT count(*) FROM (SELECT * FROM b EXCEPT SELECT * FROM a) y) AS solo_en_b,
    (SELECT count(*) FROM a) AS filas_a,
    (SELECT count(*) FROM b) AS filas_b;
