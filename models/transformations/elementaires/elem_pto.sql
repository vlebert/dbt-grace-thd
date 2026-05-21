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
  ad.ad_code,
  ad.ad_batcode,
  ad.geom AS geom
FROM {{ ref('t_ebp') }} AS bp
INNER JOIN {{ ref('t_local') }} AS lc
  ON bp.bp_lc_code = lc.lc_code
LEFT JOIN {{ ref('t_site') }} AS st
  ON lc.lc_st_code = st.st_code
LEFT JOIN {{ ref('t_adresse') }} AS ad
  ON st.st_ad_code = ad.ad_code
WHERE bp.bp_typelog = 'PTO' AND st.st_typelog = 'CLIENT'
