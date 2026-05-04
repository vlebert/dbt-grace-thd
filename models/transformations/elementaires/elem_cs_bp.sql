{{
  config(
    materialized = 'table',
    tags = ['elem']
  )
}}

SELECT
  row_number() OVER (ORDER BY cs.cs_code) AS id,
  cs.*,
  bp.geom AS geom
FROM {{ source('gracethd', 't_cassette') }} AS cs
INNER JOIN {{ ref('elem_bp') }} AS bp 
  ON cs.cs_bp_code = bp.bp_code
