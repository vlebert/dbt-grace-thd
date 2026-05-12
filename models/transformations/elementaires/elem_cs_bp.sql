{{
  config(
    materialized = 'table',
    tags = ['elem'],
    post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"]
  )
}}

SELECT
  row_number() OVER (ORDER BY cs.cs_code) AS id,
  cs.cs_code,
  cs.cs_bp_code,
  cs.cs_num,
  cs.cs_type,
  cs.cs_face,
  cs.cs_rf_code,
  bp.geom AS geom
FROM {{ ref('t_cassette') }} AS cs
INNER JOIN {{ ref('elem_bp') }} AS bp
  ON cs.cs_bp_code = bp.bp_code
