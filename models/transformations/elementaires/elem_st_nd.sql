{{
  config(
    materialized = 'table',
    tags = ['elem'],
    post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"]
  )
}}

SELECT
  row_number() OVER (ORDER BY st.st_code) AS id,
  st.st_code,
  st.st_perirec,
  st.st_nd_code,
  st.st_codeext,
  st.st_abandon,
  st.st_nra,
  st.st_prop,
  st.st_gest,
  st.st_proptyp,
  st.st_statut,
  st.st_dateins,
  st.st_avct,
  st.st_typephy,
  st.st_typelog,
  st.st_design,
  st.st_ad_code,
  st.st_postal,
  st.st_insee,
  st.st_commune,
  st.st_nomvoie,
  st.st_numero,
  st.st_rep,
  st.st_nombat,
  nd.geom AS geom
FROM {{ source('gracethd', 't_site') }} AS st
LEFT JOIN {{ source('gracethd', 't_noeud') }} AS nd 
  ON st.st_nd_code = nd.nd_code
