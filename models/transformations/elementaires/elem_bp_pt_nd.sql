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
  nd.geom AS geom
FROM {{ ref('t_ebp') }} AS bp
INNER JOIN {{ ref('t_ptech') }} AS pt
  ON bp.bp_pt_code = pt.pt_code
LEFT JOIN {{ ref('t_noeud') }} AS nd
  ON pt.pt_nd_code = nd.nd_code
