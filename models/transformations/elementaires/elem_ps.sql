{{
  config(
    tags = ['grace_elem']
  )
}}

WITH combined AS (
  SELECT
    id,
    ps_code,
    ps_1,
    ps_2,
    ps_numero,
    ps_cs_code,
    ps_type,
    ps_fonct,
    ps_preaff,
    ps_ti_code,
    geom
  FROM {{ ref('elem_ps_cs') }}
  UNION ALL
  SELECT
    id,
    ps_code,
    ps_1,
    ps_2,
    ps_numero,
    ps_cs_code,
    ps_type,
    ps_fonct,
    ps_preaff,
    ps_ti_code,
    geom
  FROM {{ ref('elem_ps_ti') }}
)
SELECT
  id,
  ps_code,
  ps_1,
  ps_2,
  ps_numero,
  ps_cs_code,
  ps_type,
  ps_fonct,
  ps_preaff,
  ps_ti_code,
  geom
FROM combined
