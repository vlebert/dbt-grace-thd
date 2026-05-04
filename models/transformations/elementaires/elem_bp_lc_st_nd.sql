{{
  config(
    materialized = 'table',
    tags = ['elem']
  )
}}

SELECT
  row_number() OVER (ORDER BY bp.bp_code) AS id,
  bp.*,
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
