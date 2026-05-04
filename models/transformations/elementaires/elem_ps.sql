{{
  config(
    materialized = 'table',
    tags = ['elem'],
    post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"]
  )
}}

WITH combined AS (
  SELECT
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
  row_number() OVER (ORDER BY ps_code) AS id,
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
