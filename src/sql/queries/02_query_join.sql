-- ============================================================================
-- CONSULTA B: variante equivalente con JOIN, CTE y EXISTS
-- ============================================================================
-- Devuelve exactamente las mismas filas que 01_query_where.sql, pero con una
-- forma distinta: CTE para el filtro de películas, JOIN para géneros y EXISTS
-- para el país.
-- ============================================================================

WITH base AS (
    SELECT
        m.movie_id,
        m.name,
        m.release_year,
        m.rating
    FROM movies m
    WHERE m.release_year BETWEEN 2000 AND 2009
      AND m.rating >= 4.0
)
SELECT DISTINCT
    b.movie_id,
    b.name,
    b.release_year,
    b.rating
FROM base b
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
ORDER BY b.rating DESC, b.name;
