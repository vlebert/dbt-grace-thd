{{
    config(
        materialized = 'table',
        schema = 'transformations'
    )
}}

SELECT
    CASE WHEN pg_input_is_valid(NULLIF(rf_code::text, ''), 'varchar(254)') THEN rf_code::VARCHAR(254) ELSE NULL END AS rf_code,
    CASE WHEN pg_input_is_valid(NULLIF(rf_design::text, ''), 'varchar(254)') THEN rf_design::VARCHAR(254) ELSE NULL END AS rf_design,
    CASE WHEN pg_input_is_valid(NULLIF(rf_type::text, ''), 'varchar(2)') THEN rf_type::VARCHAR(2) ELSE NULL END AS rf_type
FROM {{ source('gracethd', 't_reference') }}
