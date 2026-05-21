{{
  config(
    tags = ['grace_elem']
  )
}}

WITH combined AS (
  SELECT
    id,
    cs_code,
    cs_bp_code,
    cs_num,
    cs_type,
    cs_face,
    cs_rf_code,
    geom
  FROM {{ ref('elem_cs_bp') }}
  UNION ALL
  SELECT
    id,
    cs_code,
    cs_bp_code,
    cs_num,
    cs_type,
    cs_face,
    cs_rf_code,
    geom
  FROM {{ ref('elem_cs_ti') }}
)
SELECT
  id,
  cs_code,
  cs_bp_code,
  cs_num,
  cs_type,
  cs_face,
  cs_rf_code,
  geom
FROM combined
