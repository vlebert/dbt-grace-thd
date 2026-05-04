{{
  config(
    materialized = 'table',
    tags = ['elem'],
    post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"]
  )
}}

WITH combined AS (
  SELECT
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
  row_number() OVER (ORDER BY cs_code) AS id,
  cs_code,
  cs_bp_code,
  cs_num,
  cs_type,
  cs_face,
  cs_rf_code,
  geom
FROM combined
