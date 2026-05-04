{{
  config(
    materialized = 'table',
    tags = ['elem']
  )
}}

SELECT
  row_number() OVER (ORDER BY cb.cb_code) AS id,
  cb.*,
  cl.geom AS geom
FROM {{ source('gracethd', 't_cable') }} AS cb
JOIN {{ source('gracethd', 't_cableline') }} AS cl 
  ON cl.cl_cb_code = cb.cb_code
