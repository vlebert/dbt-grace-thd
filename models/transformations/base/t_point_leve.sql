{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['grace_base'],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['pl_code'], 'type': 'btree'},
            {'columns': ['geom'], 'type': 'gist'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY pl_code) AS id,
    geom AS geom,
    CASE WHEN pg_input_is_valid(NULLIF(pl_charge::text, ''), 'numeric(6,2)') THEN pl_charge::NUMERIC(6,2) ELSE NULL END AS pl_charge,
    CASE WHEN pg_input_is_valid(NULLIF(pl_code::text, ''), 'varchar(254)') THEN pl_code::VARCHAR(254) ELSE NULL END AS pl_code,
    CASE WHEN pg_input_is_valid(NULLIF(pl_x::text, ''), 'numeric') THEN pl_x::NUMERIC ELSE NULL END AS pl_x,
    CASE WHEN pg_input_is_valid(NULLIF(pl_y::text, ''), 'numeric') THEN pl_y::NUMERIC ELSE NULL END AS pl_y,
    CASE WHEN pg_input_is_valid(NULLIF(pl_z::text, ''), 'numeric') THEN pl_z::NUMERIC ELSE NULL END AS pl_z
FROM {{ source('gracethd', 't_point_leve') }}
