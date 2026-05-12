{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['base'],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['bp_code'], 'type': 'btree'},
            {'columns': ['bp_pt_code'], 'type': 'btree'},
            {'columns': ['bp_prop'], 'type': 'btree'},
            {'columns': ['bp_gest'], 'type': 'btree'},
            {'columns': ['bp_proptyp'], 'type': 'btree'},
            {'columns': ['bp_statut'], 'type': 'btree'},
            {'columns': ['bp_avct'], 'type': 'btree'},
            {'columns': ['bp_rf_code'], 'type': 'btree'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY bp_code) AS id,
    CASE WHEN pg_input_is_valid(NULLIF(bp_abandon::text, ''), 'varchar(1)') THEN bp_abandon::VARCHAR(1) ELSE NULL END AS bp_abandon,
    CASE WHEN pg_input_is_valid(NULLIF(bp_avct::text, ''), 'varchar(1)') THEN bp_avct::VARCHAR(1) ELSE NULL END AS bp_avct,
    CASE WHEN pg_input_is_valid(NULLIF(bp_code::text, ''), 'varchar(254)') THEN bp_code::VARCHAR(254) ELSE NULL END AS bp_code,
    CASE WHEN pg_input_is_valid(NULLIF(bp_codeext::text, ''), 'varchar(254)') THEN bp_codeext::VARCHAR(254) ELSE NULL END AS bp_codeext,
    CASE WHEN pg_input_is_valid(NULLIF(bp_dateins::text, ''), 'date') THEN bp_dateins::DATE ELSE NULL END AS bp_dateins,
    CASE WHEN pg_input_is_valid(NULLIF(bp_etiquet::text, ''), 'varchar(254)') THEN bp_etiquet::VARCHAR(254) ELSE NULL END AS bp_etiquet,
    CASE WHEN pg_input_is_valid(NULLIF(bp_gest::text, ''), 'varchar(20)') THEN bp_gest::VARCHAR(20) ELSE NULL END AS bp_gest,
    CASE WHEN pg_input_is_valid(NULLIF(bp_lc_code::text, ''), 'varchar(254)') THEN bp_lc_code::VARCHAR(254) ELSE NULL END AS bp_lc_code,
    CASE WHEN pg_input_is_valid(NULLIF(bp_perirec::text, ''), 'varchar(254)') THEN bp_perirec::VARCHAR(254) ELSE NULL END AS bp_perirec,
    CASE WHEN pg_input_is_valid(NULLIF(bp_prop::text, ''), 'varchar(20)') THEN bp_prop::VARCHAR(20) ELSE NULL END AS bp_prop,
    CASE WHEN pg_input_is_valid(NULLIF(bp_proptyp::text, ''), 'varchar(3)') THEN bp_proptyp::VARCHAR(3) ELSE NULL END AS bp_proptyp,
    CASE WHEN pg_input_is_valid(NULLIF(bp_pt_code::text, ''), 'varchar(254)') THEN bp_pt_code::VARCHAR(254) ELSE NULL END AS bp_pt_code,
    CASE WHEN pg_input_is_valid(NULLIF(bp_rf_code::text, ''), 'varchar(254)') THEN bp_rf_code::VARCHAR(254) ELSE NULL END AS bp_rf_code,
    CASE WHEN pg_input_is_valid(NULLIF(bp_statut::text, ''), 'varchar(3)') THEN bp_statut::VARCHAR(3) ELSE NULL END AS bp_statut,
    CASE WHEN pg_input_is_valid(NULLIF(bp_typelog::text, ''), 'varchar(3)') THEN bp_typelog::VARCHAR(3) ELSE NULL END AS bp_typelog,
    CASE WHEN pg_input_is_valid(NULLIF(bp_typephy::text, ''), 'varchar(5)') THEN bp_typephy::VARCHAR(5) ELSE NULL END AS bp_typephy
FROM {{ source('gracethd', 't_ebp') }}
