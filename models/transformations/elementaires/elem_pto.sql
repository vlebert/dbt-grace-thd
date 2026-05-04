{{
  config(
    materialized = 'table',
    tags = ['elem']
  )
}}

SELECT
  row_number() OVER (ORDER BY bp.bp_code, bp.bp_statut) AS id,
  bp.*,
  ad.ad_code,
  ad.ad_batcode,
  ad.geom AS geom
FROM {{ source('gracethd', 't_ebp') }} AS bp
INNER JOIN {{ source('gracethd', 't_local') }} AS lc 
  ON bp.bp_lc_code = lc.lc_code
LEFT JOIN {{ source('gracethd', 't_site') }} AS st 
  ON lc.lc_st_code = st.st_code
LEFT JOIN {{ source('gracethd', 't_adresse') }} AS ad 
  ON st.st_ad_code = ad.ad_code
WHERE bp.bp_typelog = 'PTO' AND st.st_typelog = 'CLIENT'
