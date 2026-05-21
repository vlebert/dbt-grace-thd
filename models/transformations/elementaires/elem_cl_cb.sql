{{
  config(
    tags = ['grace_elem']
  )
}}

SELECT
  cb.id,
  cb.cb_code,
  cb.cb_codeext,
  cb.cb_abandon,
  cb.cb_perirec,
  cb.cb_etiquet,
  cb.cb_nd1,
  cb.cb_nd2,
  cb.cb_bp1,
  cb.cb_ba1,
  cb.cb_bp2,
  cb.cb_ba2,
  cb.cb_r1_code,
  cb.cb_r2_code,
  cb.cb_r3_code,
  cb.cb_fo_type,
  cb.cb_prop,
  cb.cb_gest,
  cb.cb_proptyp,
  cb.cb_statut,
  cb.cb_dateins,
  cb.cb_avct,
  cb.cb_typephy,
  cb.cb_typelog,
  cb.cb_rf_code,
  cb.cb_capafo,
  cb.cb_fo_disp,
  cb.cb_fo_util,
  cb.cb_modulo,
  cb.cb_cabphy,
  cb.cb_lgreel,
  cl.geom AS geom
FROM {{ ref('t_cable') }} AS cb
JOIN {{ ref('t_cableline') }} AS cl
  ON cl.cl_cb_code = cb.cb_code
