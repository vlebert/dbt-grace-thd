SELECT
  ti.id,
  ti.ti_code,
  ti.ti_codeext,
  ti.ti_perirec,
  ti.ti_abandon,
  ti.ti_etiquet,
  ti.ti_ba_code,
  ti.ti_prop,
  ti.ti_type,
  ti.ti_rf_code,
  ti.ti_taille,
  ti.ti_placemt,
  nd.geom AS geom
FROM {{ ref('t_tiroir') }} AS ti
LEFT JOIN {{ ref('t_baie') }} AS ba
  ON ti.ti_ba_code = ba.ba_code
LEFT JOIN {{ ref('t_local') }} AS lc
  ON ba.ba_lc_code = lc.lc_code
LEFT JOIN {{ ref('t_site') }} AS st
  ON lc.lc_st_code = st.st_code
LEFT JOIN {{ ref('t_noeud') }} AS nd
  ON st.st_nd_code = nd.nd_code
