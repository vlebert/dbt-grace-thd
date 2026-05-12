{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['base'],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['ps_code'], 'type': 'btree'},
            {'columns': ['ps_numero'], 'type': 'btree'},
            {'columns': ['ps_1'], 'type': 'btree'},
            {'columns': ['ps_2'], 'type': 'btree'},
            {'columns': ['ps_cs_code'], 'type': 'btree'},
            {'columns': ['ps_ti_code'], 'type': 'btree'},
            {'columns': ['ps_type'], 'type': 'btree'},
            {'columns': ['ps_fonct'], 'type': 'btree'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY ps_code) AS id,
    CASE WHEN pg_input_is_valid(NULLIF(ps_1::text, ''), 'varchar(254)') THEN ps_1::VARCHAR(254) ELSE NULL END AS ps_1,
    CASE WHEN pg_input_is_valid(NULLIF(ps_2::text, ''), 'varchar(254)') THEN ps_2::VARCHAR(254) ELSE NULL END AS ps_2,
    CASE WHEN pg_input_is_valid(NULLIF(ps_code::text, ''), 'varchar(254)') THEN ps_code::VARCHAR(254) ELSE NULL END AS ps_code,
    CASE WHEN pg_input_is_valid(NULLIF(ps_cs_code::text, ''), 'varchar(254)') THEN ps_cs_code::VARCHAR(254) ELSE NULL END AS ps_cs_code,
    CASE WHEN pg_input_is_valid(NULLIF(ps_fonct::text, ''), 'varchar(2)') THEN ps_fonct::VARCHAR(2) ELSE NULL END AS ps_fonct,
    CASE WHEN pg_input_is_valid(NULLIF(ps_numero::text, ''), 'integer') THEN ps_numero::INTEGER ELSE NULL END AS ps_numero,
    CASE WHEN pg_input_is_valid(NULLIF(ps_preaff::text, ''), 'varchar(50)') THEN ps_preaff::VARCHAR(50) ELSE NULL END AS ps_preaff,
    CASE WHEN pg_input_is_valid(NULLIF(ps_ti_code::text, ''), 'varchar(254)') THEN ps_ti_code::VARCHAR(254) ELSE NULL END AS ps_ti_code,
    CASE WHEN pg_input_is_valid(NULLIF(ps_type::text, ''), 'varchar(10)') THEN ps_type::VARCHAR(10) ELSE NULL END AS ps_type
FROM {{ source('gracethd', 't_position') }}
