{{
  config(
    tags = ['grace_elem']
  )
}}

WITH data AS (
  -- Câbles avec géométrie dans cableline (MULTILINESTRING possible)
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
    ST_LineMerge(cl.geom) AS geom
  FROM {{ ref('t_cable') }} AS cb
  JOIN {{ ref('t_cableline') }} AS cl
    ON cl.cl_cb_code = cb.cb_code

  UNION ALL

  -- Câbles sans cableline : construction géométrie depuis nd1/nd2
  -- t_noeud.geom est MULTIPOINT, on extrait un POINT avec ST_PointOnSurface
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
    CASE 
      WHEN nd1.geom IS NOT NULL AND nd2.geom IS NOT NULL
      THEN ST_MakeLine(ST_PointOnSurface(nd1.geom), ST_PointOnSurface(nd2.geom))
      ELSE NULL 
    END AS geom
  FROM {{ ref('t_cable') }} AS cb
  LEFT JOIN {{ ref('t_noeud') }} AS nd1
    ON cb.cb_nd1 = nd1.nd_code
  LEFT JOIN {{ ref('t_noeud') }} AS nd2
    ON cb.cb_nd2 = nd2.nd_code
  LEFT JOIN {{ ref('t_cableline') }} AS cl
    ON cl.cl_cb_code = cb.cb_code
  WHERE cl.cl_code IS NULL
    AND nd1.geom IS NOT NULL
    AND nd2.geom IS NOT NULL
)

SELECT
  id,
  cb_code,
  cb_codeext,
  cb_abandon,
  cb_perirec,
  cb_etiquet,
  cb_nd1,
  cb_nd2,
  cb_bp1,
  cb_ba1,
  cb_bp2,
  cb_ba2,
  cb_r1_code,
  cb_r2_code,
  cb_r3_code,
  cb_fo_type,
  cb_prop,
  cb_gest,
  cb_proptyp,
  cb_statut,
  cb_dateins,
  cb_avct,
  cb_typephy,
  cb_typelog,
  cb_rf_code,
  cb_capafo,
  cb_fo_disp,
  cb_fo_util,
  cb_modulo,
  cb_cabphy,
  cb_lgreel,
  geom
FROM data
