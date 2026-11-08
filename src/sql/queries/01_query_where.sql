-- películas de Drama o Comedia, estrenadas en Estados Unidos entre 2000 y 2009, con rating >= 4.0.

SELECT DISTINCT
    m.movie_id,
    m.name,
    m.release_year,
    m.rating
FROM movies m,
     movie_genres mg,
     genres g,
     movie_countries mc,
     countries c
WHERE m.movie_id = mg.movie_id
  AND mg.genre_id = g.genre_id
  AND m.movie_id = mc.movie_id
  AND mc.country_id = c.country_id
  AND (g.name = 'Drama' OR g.name = 'Comedy')
  AND c.name IN ('USA')
  AND m.release_year BETWEEN 2000 AND 2009
  AND m.rating >= 4.0
ORDER BY m.rating DESC, m.name;
