{{
  config(
    tags = ['grace_elem']
  )
}}

SELECT
  bp.id,
  bp.bp_code,
  bp.bp_pt_code,
  bp.bp_perirec,
  bp.bp_etiquet,
  bp.bp_codeext,
  bp.bp_abandon,
  bp.bp_lc_code,
  bp.bp_prop,
  bp.bp_gest,
  bp.bp_proptyp,
  bp.bp_statut,
  bp.bp_dateins,
  bp.bp_avct,
  bp.bp_typephy,
  bp.bp_typelog,
  bp.bp_rf_code,
  COALESCE(nd1.geom, nd2.geom) AS geom
FROM {{ ref('t_ebp') }} AS bp
LEFT JOIN {{ ref('t_ptech') }} AS pt
  ON bp.bp_pt_code = pt.pt_code
LEFT JOIN {{ ref('t_noeud') }} AS nd1
  ON pt.pt_nd_code = nd1.nd_code
LEFT JOIN {{ ref('t_local') }} AS lc
  ON bp.bp_lc_code = lc.lc_code
LEFT JOIN {{ ref('t_site') }} AS st
  ON lc.lc_st_code = st.st_code
LEFT JOIN {{ ref('t_noeud') }} AS nd2
  ON st.st_nd_code = nd2.nd_code
WHERE bp.bp_typelog IN ('PBO', 'BPE')
