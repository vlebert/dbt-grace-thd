{{
  config(
    materialized = 'table',
    tags = ['elem']
  )
}}

SELECT
  row_number() OVER (ORDER BY ti.ti_code) AS id,
  ti.*,
  nd.geom AS geom
FROM {{ source('gracethd', 't_tiroir') }} AS ti
LEFT JOIN {{ source('gracethd', 't_baie') }} AS ba 
  ON ti.ti_ba_code = ba.ba_code
LEFT JOIN {{ source('gracethd', 't_local') }} AS lc 
  ON ba.ba_lc_code = lc.lc_code
LEFT JOIN {{ source('gracethd', 't_site') }} AS st 
  ON lc.lc_st_code = st.st_code
LEFT JOIN {{ source('gracethd', 't_noeud') }} AS nd 
  ON st.st_nd_code = nd.nd_code
