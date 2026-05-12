{{
  config(
    tags = ['elem']
  )
}}

SELECT
  fo.id,
  fo.fo_code,
  fo.fo_cb_code,
  fo.fo_nincab,
  fo.fo_numtub,
  fo.fo_nintub,
  fo.fo_etat,
  cl.geom AS geom
FROM {{ ref('t_fibre') }} AS fo
JOIN {{ ref('t_cable') }} AS cb
  ON fo.fo_cb_code = cb.cb_code
JOIN {{ ref('t_cableline') }} AS cl
  ON cl.cl_cb_code = cb.cb_code
