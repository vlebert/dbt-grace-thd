{{
  config(
    materialized = 'table',
    tags = ['elem']
  )
}}

SELECT
  row_number() OVER (ORDER BY bp.bp_code) AS id,
  bp.*,
  COALESCE(nd1.geom, nd2.geom) AS geom
FROM {{ source('gracethd', 't_ebp') }} AS bp
LEFT JOIN {{ source('gracethd', 't_ptech') }} AS pt 
  ON bp.bp_pt_code = pt.pt_code
LEFT JOIN {{ source('gracethd', 't_noeud') }} AS nd1 
  ON pt.pt_nd_code = nd1.nd_code
LEFT JOIN {{ source('gracethd', 't_local') }} AS lc 
  ON bp.bp_lc_code = lc.lc_code
LEFT JOIN {{ source('gracethd', 't_site') }} AS st 
  ON lc.lc_st_code = st.st_code
LEFT JOIN {{ source('gracethd', 't_noeud') }} AS nd2 
  ON st.st_nd_code = nd2.nd_code
WHERE bp.bp_typelog IN ('PBO', 'BPE')
