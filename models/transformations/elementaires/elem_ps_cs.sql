{{
  config(
    materialized = 'table',
    tags = ['elem']
  )
}}

SELECT
  row_number() OVER (ORDER BY ps.ps_code) AS id,
  ps.*,
  cs.geom AS geom
FROM {{ source('gracethd', 't_position') }} AS ps
INNER JOIN {{ ref('elem_cs') }} AS cs 
  ON ps.ps_cs_code = cs.cs_code
