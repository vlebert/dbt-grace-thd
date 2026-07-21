-- Les positions sont dédoublonnées sur (ps_cs_code, ps_ti_code) avant les
-- jointures : t_position contient une ligne par fibre, ce qui provoquerait un
-- fan-out coûteux avec la géométrie en charge utile.
WITH cs_ti AS (
  SELECT DISTINCT
    ps_cs_code,
    ps_ti_code
  FROM {{ ref('t_position') }}
  WHERE ps_ti_code IS NOT NULL
)
SELECT
  cs.id,
  cs.cs_code,
  cs.cs_bp_code,
  cs.cs_num,
  cs.cs_type,
  cs.cs_face,
  cs.cs_rf_code,
  ti.geom AS geom
FROM {{ ref('t_cassette') }} AS cs
INNER JOIN cs_ti
  ON cs.cs_code = cs_ti.ps_cs_code
INNER JOIN {{ ref('elem_ti_ba_lc_st_nd') }} AS ti
  ON ti.ti_code = cs_ti.ps_ti_code
WHERE cs.cs_bp_code IS NULL OR cs.cs_bp_code <> ''
