{{
    config(
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['ti_code'], 'type': 'btree'},
            {'columns': ['ti_ba_code'], 'type': 'btree'},
            {'columns': ['ti_prop'], 'type': 'btree'},
            {'columns': ['ti_type'], 'type': 'btree'},
            {'columns': ['ti_rf_code'], 'type': 'btree'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY ti_code)::int4 AS id,
    CASE WHEN pg_input_is_valid(NULLIF(ti_abandon::text, ''), 'varchar(1)') THEN ti_abandon::VARCHAR(1) ELSE NULL END AS ti_abandon,
    CASE WHEN pg_input_is_valid(NULLIF(ti_ba_code::text, ''), 'varchar(254)') THEN ti_ba_code::VARCHAR(254) ELSE NULL END AS ti_ba_code,
    CASE WHEN pg_input_is_valid(NULLIF(ti_code::text, ''), 'varchar(254)') THEN ti_code::VARCHAR(254) ELSE NULL END AS ti_code,
    CASE WHEN pg_input_is_valid(NULLIF(ti_codeext::text, ''), 'varchar(254)') THEN ti_codeext::VARCHAR(254) ELSE NULL END AS ti_codeext,
    CASE WHEN pg_input_is_valid(NULLIF(ti_etiquet::text, ''), 'varchar(254)') THEN ti_etiquet::VARCHAR(254) ELSE NULL END AS ti_etiquet,
    CASE WHEN pg_input_is_valid(NULLIF(ti_perirec::text, ''), 'varchar(254)') THEN ti_perirec::VARCHAR(254) ELSE NULL END AS ti_perirec,
    CASE WHEN pg_input_is_valid(NULLIF(ti_placemt::text, ''), 'numeric(5,2)') THEN ti_placemt::NUMERIC(5,2) ELSE NULL END AS ti_placemt,
    CASE WHEN pg_input_is_valid(NULLIF(ti_prop::text, ''), 'varchar(20)') THEN ti_prop::VARCHAR(20) ELSE NULL END AS ti_prop,
    CASE WHEN pg_input_is_valid(NULLIF(ti_rf_code::text, ''), 'varchar(254)') THEN ti_rf_code::VARCHAR(254) ELSE NULL END AS ti_rf_code,
    CASE WHEN pg_input_is_valid(NULLIF(ti_taille::text, ''), 'numeric(5,2)') THEN ti_taille::NUMERIC(5,2) ELSE NULL END AS ti_taille,
    CASE WHEN pg_input_is_valid(NULLIF(ti_type::text, ''), 'varchar(10)') THEN ti_type::VARCHAR(10) ELSE NULL END AS ti_type
FROM {{ source('gracethd', 't_tiroir') }}
