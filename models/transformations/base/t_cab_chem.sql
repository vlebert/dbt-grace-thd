{{
    config(
        materialized = 'table',
        schema = 'transformations'
    )
}}

SELECT
    CASE WHEN pg_input_is_valid(NULLIF(cc_cb_code::text, ''), 'varchar(254)') THEN cc_cb_code::VARCHAR(254) ELSE NULL END AS cc_cb_code,
    CASE WHEN pg_input_is_valid(NULLIF(cc_cm_code::text, ''), 'varchar(254)') THEN cc_cm_code::VARCHAR(254) ELSE NULL END AS cc_cm_code
FROM {{ source('gracethd', 't_cab_chem') }}
