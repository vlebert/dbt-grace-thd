{{
  config(
    materialized = 'table',
    tags = ['elem'],
    post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"]
  )
}}

SELECT DISTINCT
  row_number() OVER (ORDER BY cs.cs_code) AS id,
  cs.cs_code,
  cs.cs_bp_code,
  cs.cs_num,
  cs.cs_type,
  cs.cs_face,
  cs.cs_rf_code,
  ti.geom AS geom
FROM {{ source('gracethd', 't_cassette') }} AS cs
INNER JOIN {{ source('gracethd', 't_position') }} AS ps
  ON cs.cs_code = ps.ps_cs_code
  AND ps.ps_ti_code IS NOT NULL
INNER JOIN {{ ref('elem_ti_ba_lc_st_nd') }} AS ti
  ON ti.ti_code = ps.ps_ti_code
WHERE cs.cs_bp_code IS NULL OR cs.cs_bp_code <> ''
