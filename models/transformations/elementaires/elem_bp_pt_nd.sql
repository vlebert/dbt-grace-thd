{{
  config(
    materialized = 'table',
    tags = ['elem']
  )
}}

SELECT
  row_number() OVER (ORDER BY bp.bp_code) AS id,
  bp.*,
  nd.geom AS geom
FROM {{ source('gracethd', 't_ebp') }} AS bp
INNER JOIN {{ source('gracethd', 't_ptech') }} AS pt 
  ON bp.bp_pt_code = pt.pt_code
LEFT JOIN {{ source('gracethd', 't_noeud') }} AS nd 
  ON pt.pt_nd_code = nd.nd_code
