{{
  config(
    materialized = 'table',
    tags = ['elem']
  )
}}

SELECT
  row_number() OVER (ORDER BY st.st_code) AS id,
  st.*,
  nd.geom AS geom
FROM {{ source('gracethd', 't_site') }} AS st
LEFT JOIN {{ source('gracethd', 't_noeud') }} AS nd 
  ON st.st_nd_code = nd.nd_code
