{{
  config(
    materialized = 'table',
    tags = ['elem'],
    post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"]
  )
}}

SELECT
  row_number() OVER (ORDER BY bp.bp_code) AS id,
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
FROM {{ source('gracethd', 't_ebp') }} AS bp
INNER JOIN {{ source('gracethd', 't_local') }} AS lc
  ON bp.bp_lc_code = lc.lc_code
LEFT JOIN {{ source('gracethd', 't_site') }} AS st
  ON lc.lc_st_code = st.st_code
LEFT JOIN {{ source('gracethd', 't_noeud') }} AS nd
  ON st.st_nd_code = nd.nd_code
LEFT JOIN {{ source('gracethd', 't_reference') }} AS rf
  ON bp.bp_rf_code = rf.rf_code
