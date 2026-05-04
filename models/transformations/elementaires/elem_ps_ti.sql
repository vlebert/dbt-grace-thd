{{
  config(
    materialized = 'table',
    tags = ['elem']
  )
}}

SELECT
  row_number() OVER (ORDER BY ps.ps_code) AS id,
  ps.*,
  ti.geom AS geom
FROM {{ source('gracethd', 't_position') }} AS ps
INNER JOIN {{ ref('elem_ti_ba_lc_st_nd') }} AS ti 
  ON ps.ps_ti_code = ti.ti_code
