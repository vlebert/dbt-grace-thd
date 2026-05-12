{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['base'],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"]
    )
}}

SELECT
    row_number() OVER (ORDER BY zd_code) AS id,
    geom AS geom,
    CASE WHEN pg_input_is_valid(NULLIF(zd_code::text, ''), 'varchar(254)') THEN zd_code::VARCHAR(254) ELSE NULL END AS zd_code,
    CASE WHEN pg_input_is_valid(NULLIF(zd_nd_code::text, ''), 'varchar(254)') THEN zd_nd_code::VARCHAR(254) ELSE NULL END AS zd_nd_code,
    CASE WHEN pg_input_is_valid(NULLIF(zd_r1_code::text, ''), 'varchar(100)') THEN zd_r1_code::VARCHAR(100) ELSE NULL END AS zd_r1_code,
    CASE WHEN pg_input_is_valid(NULLIF(zd_r2_code::text, ''), 'varchar(100)') THEN zd_r2_code::VARCHAR(100) ELSE NULL END AS zd_r2_code,
    CASE WHEN pg_input_is_valid(NULLIF(zd_r3_code::text, ''), 'varchar(100)') THEN zd_r3_code::VARCHAR(100) ELSE NULL END AS zd_r3_code,
    CASE WHEN pg_input_is_valid(NULLIF(zd_r4_code::text, ''), 'varchar(100)') THEN zd_r4_code::VARCHAR(100) ELSE NULL END AS zd_r4_code,
    CASE WHEN pg_input_is_valid(NULLIF(zd_statut::text, ''), 'varchar(3)') THEN zd_statut::VARCHAR(3) ELSE NULL END AS zd_statut,
    CASE WHEN pg_input_is_valid(NULLIF(zd_zs_code::text, ''), 'varchar(254)') THEN zd_zs_code::VARCHAR(254) ELSE NULL END AS zd_zs_code
FROM {{ source('gracethd', 't_zdep') }}
