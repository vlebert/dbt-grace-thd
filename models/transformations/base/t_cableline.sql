{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['grace_base'],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['cl_code'], 'type': 'btree'},
            {'columns': ['geom'], 'type': 'gist'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY cl_code) AS id,
    CASE WHEN pg_input_is_valid(NULLIF(cl_cb_code::text, ''), 'varchar(254)') THEN cl_cb_code::VARCHAR(254) ELSE NULL END AS cl_cb_code,
    CASE WHEN pg_input_is_valid(NULLIF(cl_code::text, ''), 'varchar(254)') THEN cl_code::VARCHAR(254) ELSE NULL END AS cl_code,
    geom AS geom
FROM {{ source('gracethd', 't_cableline') }}
