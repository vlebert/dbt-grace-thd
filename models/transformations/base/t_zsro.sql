{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['grace_base'],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['zs_code'], 'type': 'btree'},
            {'columns': ['geom'], 'type': 'gist'},
            {'columns': ['zs_zn_code'], 'type': 'btree'},
            {'columns': ['zs_r1_code'], 'type': 'btree'},
            {'columns': ['zs_r2_code'], 'type': 'btree'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY zs_code) AS id,
    geom AS geom,
    CASE WHEN pg_input_is_valid(NULLIF(zs_actif::text, ''), 'varchar(1)') THEN zs_actif::VARCHAR(1) ELSE NULL END AS zs_actif,
    CASE WHEN pg_input_is_valid(NULLIF(zs_capamax::text, ''), 'integer') THEN zs_capamax::INTEGER ELSE NULL END AS zs_capamax,
    CASE WHEN pg_input_is_valid(NULLIF(zs_code::text, ''), 'varchar(254)') THEN zs_code::VARCHAR(254) ELSE NULL END AS zs_code,
    CASE WHEN pg_input_is_valid(NULLIF(zs_etatpm::text, ''), 'varchar(2)') THEN zs_etatpm::VARCHAR(2) ELSE NULL END AS zs_etatpm,
    CASE WHEN pg_input_is_valid(NULLIF(zs_lc_code::text, ''), 'varchar(254)') THEN zs_lc_code::VARCHAR(254) ELSE NULL END AS zs_lc_code,
    CASE WHEN pg_input_is_valid(NULLIF(zs_lgmaxln::text, ''), 'numeric(5,2)') THEN zs_lgmaxln::NUMERIC(5,2) ELSE NULL END AS zs_lgmaxln,
    CASE WHEN pg_input_is_valid(NULLIF(zs_nblogmt::text, ''), 'integer') THEN zs_nblogmt::INTEGER ELSE NULL END AS zs_nblogmt,
    CASE WHEN pg_input_is_valid(NULLIF(zs_nom::text, ''), 'varchar(30)') THEN zs_nom::VARCHAR(30) ELSE NULL END AS zs_nom,
    CASE WHEN pg_input_is_valid(NULLIF(zs_r1_code::text, ''), 'varchar(100)') THEN zs_r1_code::VARCHAR(100) ELSE NULL END AS zs_r1_code,
    CASE WHEN pg_input_is_valid(NULLIF(zs_r2_code::text, ''), 'varchar(100)') THEN zs_r2_code::VARCHAR(100) ELSE NULL END AS zs_r2_code,
    CASE WHEN pg_input_is_valid(NULLIF(zs_r3_code::text, ''), 'varchar(100)') THEN zs_r3_code::VARCHAR(100) ELSE NULL END AS zs_r3_code,
    CASE WHEN pg_input_is_valid(NULLIF(zs_refpm::text, ''), 'varchar(20)') THEN zs_refpm::VARCHAR(20) ELSE NULL END AS zs_refpm,
    CASE WHEN pg_input_is_valid(NULLIF(zs_zn_code::text, ''), 'varchar(254)') THEN zs_zn_code::VARCHAR(254) ELSE NULL END AS zs_zn_code,
    CASE WHEN pg_input_is_valid(NULLIF(zs_znllong::text, ''), 'numeric(5,2)') THEN zs_znllong::NUMERIC(5,2) ELSE NULL END AS zs_znllong
FROM {{ source('gracethd', 't_zsro') }}
