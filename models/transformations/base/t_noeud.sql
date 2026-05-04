{{
    config(
        materialized = 'table',
        schema = 'transformations'
    )
}}

SELECT
    geom AS geom,
    CASE WHEN pg_input_is_valid(NULLIF(nd_code::text, ''), 'varchar(254)') THEN nd_code::VARCHAR(254) ELSE NULL END AS nd_code
FROM {{ source('gracethd', 't_noeud') }}
