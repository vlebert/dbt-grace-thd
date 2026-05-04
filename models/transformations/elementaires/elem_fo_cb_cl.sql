{{
  config(
    materialized = 'table',
    tags = ['elem']
  )
}}

SELECT
  row_number() OVER (ORDER BY fo.fo_code) AS id,
  fo.*,
  cl.geom AS geom
FROM {{ source('gracethd', 't_fibre') }} AS fo
JOIN {{ source('gracethd', 't_cable') }} AS cb 
  ON fo.fo_cb_code = cb.cb_code
JOIN {{ source('gracethd', 't_cableline') }} AS cl 
  ON cl.cl_cb_code = cb.cb_code
