{{
  config(
    materialized = 'table',
    tags = ['elem'],
    post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"]
  )
}}

SELECT
  row_number() OVER (ORDER BY fo.fo_code) AS id,
  fo.fo_code,
  fo.fo_cb_code,
  fo.fo_nincab,
  fo.fo_numtub,
  fo.fo_nintub,
  fo.fo_etat,
  cl.geom AS geom
FROM {{ source('gracethd', 't_fibre') }} AS fo
JOIN {{ source('gracethd', 't_cable') }} AS cb
  ON fo.fo_cb_code = cb.cb_code
JOIN {{ source('gracethd', 't_cableline') }} AS cl
  ON cl.cl_cb_code = cb.cb_code
