{{
  config(
    materialized = 'table',
    tags = ['elem']
  )
}}

SELECT
  row_number() OVER (ORDER BY pt.pt_code) AS id,
  pt.*,
  nd.geom AS geom
FROM {{ source('gracethd', 't_ptech') }} AS pt
LEFT JOIN {{ source('gracethd', 't_noeud') }} AS nd 
  ON pt.pt_nd_code = nd.nd_code
