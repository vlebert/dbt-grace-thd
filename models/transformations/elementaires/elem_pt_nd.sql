{{
  config(
    tags = ['grace_elem']
  )
}}

SELECT
  pt.id,
  pt.pt_code,
  pt.pt_codeext,
  pt.pt_abandon,
  pt.pt_etiquet,
  pt.pt_perirec,
  pt.pt_nd_code,
  pt.pt_prop,
  pt.pt_gest,
  pt.pt_proptyp,
  pt.pt_statut,
  pt.pt_avct,
  pt.pt_typephy,
  pt.pt_nature,
  pt.pt_secu,
  pt.pt_a_struc,
  pt.pt_a_haut,
  nd.geom AS geom
FROM {{ ref('t_ptech') }} AS pt
LEFT JOIN {{ ref('t_noeud') }} AS nd
  ON pt.pt_nd_code = nd.nd_code
