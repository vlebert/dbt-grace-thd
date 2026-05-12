{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['base'],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['nd_code'], 'type': 'btree'},
            {'columns': ['geom'], 'type': 'gist'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY nd_code) AS id,
    geom AS geom,
    CASE WHEN pg_input_is_valid(NULLIF(nd_code::text, ''), 'varchar(254)') THEN nd_code::VARCHAR(254) ELSE NULL END AS nd_code
FROM {{ source('gracethd', 't_noeud') }}
