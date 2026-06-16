{{
    config(
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['zn_code'], 'type': 'btree'},
            {'columns': ['geom'], 'type': 'gist'},
            {'columns': ['zn_nd_code'], 'type': 'btree'},
            {'columns': ['zn_r1_code'], 'type': 'btree'},
            {'columns': ['zn_r2_code'], 'type': 'btree'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY zn_code)::int4 AS id,
    geom AS geom,
    CASE WHEN pg_input_is_valid(NULLIF(zn_code::text, ''), 'varchar(254)') THEN zn_code::VARCHAR(254) ELSE NULL END AS zn_code,
    CASE WHEN pg_input_is_valid(NULLIF(zn_etat::text, ''), 'varchar(2)') THEN zn_etat::VARCHAR(2) ELSE NULL END AS zn_etat,
    CASE WHEN pg_input_is_valid(NULLIF(zn_lc_code::text, ''), 'varchar(254)') THEN zn_lc_code::VARCHAR(254) ELSE NULL END AS zn_lc_code,
    CASE WHEN pg_input_is_valid(NULLIF(zn_nd_code::text, ''), 'varchar(254)') THEN zn_nd_code::VARCHAR(254) ELSE NULL END AS zn_nd_code,
    CASE WHEN pg_input_is_valid(NULLIF(zn_nom::text, ''), 'varchar(30)') THEN zn_nom::VARCHAR(30) ELSE NULL END AS zn_nom,
    CASE WHEN pg_input_is_valid(NULLIF(zn_nroref::text, ''), 'varchar(15)') THEN zn_nroref::VARCHAR(15) ELSE NULL END AS zn_nroref,
    CASE WHEN pg_input_is_valid(NULLIF(zn_r1_code::text, ''), 'varchar(100)') THEN zn_r1_code::VARCHAR(100) ELSE NULL END AS zn_r1_code,
    CASE WHEN pg_input_is_valid(NULLIF(zn_r2_code::text, ''), 'varchar(100)') THEN zn_r2_code::VARCHAR(100) ELSE NULL END AS zn_r2_code
FROM {{ source('gracethd', 't_znro') }}
