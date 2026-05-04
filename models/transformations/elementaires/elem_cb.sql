{{
  config(
    materialized = 'table',
    tags = ['elem']
  )
}}

WITH data AS (
  -- Câbles avec géométrie dans cableline (MULTILINESTRING possible)
  SELECT
    cb.*,
    ST_LineMerge(cl.geom) AS geom
  FROM {{ source('gracethd', 't_cable') }} AS cb
  JOIN {{ source('gracethd', 't_cableline') }} AS cl 
    ON cl.cl_cb_code = cb.cb_code

  UNION ALL

  -- Câbles sans cableline : construction géométrie depuis nd1/nd2
  -- t_noeud.geom est MULTIPOINT, on extrait un POINT avec ST_PointOnSurface
  SELECT
    cb.*,
    CASE 
      WHEN nd1.geom IS NOT NULL AND nd2.geom IS NOT NULL
      THEN ST_MakeLine(ST_PointOnSurface(nd1.geom), ST_PointOnSurface(nd2.geom))
      ELSE NULL 
    END AS geom
  FROM {{ source('gracethd', 't_cable') }} AS cb
  LEFT JOIN {{ source('gracethd', 't_noeud') }} AS nd1 
    ON cb.cb_nd1 = nd1.nd_code
  LEFT JOIN {{ source('gracethd', 't_noeud') }} AS nd2 
    ON cb.cb_nd2 = nd2.nd_code
  LEFT JOIN {{ source('gracethd', 't_cableline') }} AS cl 
    ON cl.cl_cb_code = cb.cb_code
  WHERE cl.cl_code IS NULL
    AND nd1.geom IS NOT NULL 
    AND nd2.geom IS NOT NULL
)

SELECT
  row_number() OVER (ORDER BY cb_code) AS id,
  *
FROM data
