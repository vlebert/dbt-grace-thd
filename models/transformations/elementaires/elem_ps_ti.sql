{{
  config(
    materialized = 'table',
    tags = ['elem'],
    post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"]
  )
}}

SELECT
  row_number() OVER (ORDER BY ps.ps_code) AS id,
  ps.ps_code,
  ps.ps_1,
  ps.ps_2,
  ps.ps_numero,
  ps.ps_cs_code,
  ps.ps_type,
  ps.ps_fonct,
  ps.ps_preaff,
  ps.ps_ti_code,
  ti.geom AS geom
FROM {{ ref('t_position') }} AS ps
INNER JOIN {{ ref('elem_ti_ba_lc_st_nd') }} AS ti
  ON ps.ps_ti_code = ti.ti_code
