{{
  config(
    tags = ['elem']
  )
}}

SELECT
  ba.id,
  ba.ba_code,
  ba.ba_codeext,
  ba.ba_perirec,
  ba.ba_abandon,
  ba.ba_etiquet,
  ba.ba_lc_code,
  ba.ba_prop,
  ba.ba_gest,
  ba.ba_proptyp,
  ba.ba_statut,
  ba.ba_rf_code,
  ba.ba_type,
  ba.ba_nb_u,
  nd.geom AS geom
FROM {{ ref('t_baie') }} AS ba
LEFT JOIN {{ ref('t_local') }} AS lc
  ON ba.ba_lc_code = lc.lc_code
LEFT JOIN {{ ref('t_site') }} AS st
  ON lc.lc_st_code = st.st_code
LEFT JOIN {{ ref('t_noeud') }} AS nd
  ON st.st_nd_code = nd.nd_code
