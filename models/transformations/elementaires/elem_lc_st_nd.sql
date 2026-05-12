{{
  config(
    materialized = 'table',
    tags = ['elem'],
    post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"]
  )
}}

SELECT
  row_number() OVER (ORDER BY lc.lc_code) AS id,
  lc.lc_code,
  lc.lc_bp_codf,
  lc.lc_bp_codp,
  lc.lc_codeext,
  lc.lc_abandon,
  lc.lc_prop,
  lc.lc_gest,
  lc.lc_statut,
  lc.lc_dateins,
  lc.lc_elec,
  lc.lc_bat,
  lc.lc_escal,
  lc.lc_etage,
  lc.lc_avct,
  lc.lc_perirec,
  lc.lc_etiquet,
  lc.lc_st_code,
  lc.lc_typelog,
  lc.lc_proptyp,
  nd.geom AS geom
FROM {{ ref('t_local') }} AS lc
LEFT JOIN {{ ref('t_site') }} AS st
  ON lc.lc_st_code = st.st_code
LEFT JOIN {{ ref('t_noeud') }} AS nd
  ON st.st_nd_code = nd.nd_code
