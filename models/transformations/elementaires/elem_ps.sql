{{
  config(
    materialized = 'table',
    tags = ['elem']
  )
}}

SELECT * FROM {{ ref('elem_ps_cs') }}
UNION ALL
SELECT * FROM {{ ref('elem_ps_ti') }}
