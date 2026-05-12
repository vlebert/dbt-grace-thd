{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['base'],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['cs_code'], 'type': 'btree'},
            {'columns': ['cs_bp_code'], 'type': 'btree'},
            {'columns': ['cs_rf_code'], 'type': 'btree'},
            {'columns': ['cs_type'], 'type': 'btree'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY cs_code) AS id,
    CASE WHEN pg_input_is_valid(NULLIF(cs_bp_code::text, ''), 'varchar(254)') THEN cs_bp_code::VARCHAR(254) ELSE NULL END AS cs_bp_code,
    CASE WHEN pg_input_is_valid(NULLIF(cs_code::text, ''), 'varchar(254)') THEN cs_code::VARCHAR(254) ELSE NULL END AS cs_code,
    CASE WHEN pg_input_is_valid(NULLIF(cs_face::text, ''), 'varchar(20)') THEN cs_face::VARCHAR(20) ELSE NULL END AS cs_face,
    CASE WHEN pg_input_is_valid(NULLIF(cs_num::text, ''), 'integer') THEN cs_num::INTEGER ELSE NULL END AS cs_num,
    CASE WHEN pg_input_is_valid(NULLIF(cs_rf_code::text, ''), 'varchar(254)') THEN cs_rf_code::VARCHAR(254) ELSE NULL END AS cs_rf_code,
    CASE WHEN pg_input_is_valid(NULLIF(cs_type::text, ''), 'varchar(1)') THEN cs_type::VARCHAR(1) ELSE NULL END AS cs_type
FROM {{ source('gracethd', 't_cassette') }}
