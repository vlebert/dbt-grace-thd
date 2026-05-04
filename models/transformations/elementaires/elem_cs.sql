{{
  config(
    materialized = 'table',
    tags = ['elem']
  )
}}

SELECT * FROM {{ ref('elem_cs_bp') }}
UNION ALL
SELECT * FROM {{ ref('elem_cs_ti') }}
