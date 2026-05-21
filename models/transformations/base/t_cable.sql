{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['grace_base'],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['cb_code'], 'type': 'btree'},
            {'columns': ['cb_nd1'], 'type': 'btree'},
            {'columns': ['cb_nd2'], 'type': 'btree'},
            {'columns': ['cb_prop'], 'type': 'btree'},
            {'columns': ['cb_gest'], 'type': 'btree'},
            {'columns': ['cb_proptyp'], 'type': 'btree'},
            {'columns': ['cb_statut'], 'type': 'btree'},
            {'columns': ['cb_avct'], 'type': 'btree'},
            {'columns': ['cb_typephy'], 'type': 'btree'},
            {'columns': ['cb_typelog'], 'type': 'btree'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY cb_code) AS id,
    CASE WHEN pg_input_is_valid(NULLIF(cb_abandon::text, ''), 'varchar(1)') THEN cb_abandon::VARCHAR(1) ELSE NULL END AS cb_abandon,
    CASE WHEN pg_input_is_valid(NULLIF(cb_avct::text, ''), 'varchar(1)') THEN cb_avct::VARCHAR(1) ELSE NULL END AS cb_avct,
    CASE WHEN pg_input_is_valid(NULLIF(cb_ba1::text, ''), 'varchar(254)') THEN cb_ba1::VARCHAR(254) ELSE NULL END AS cb_ba1,
    CASE WHEN pg_input_is_valid(NULLIF(cb_ba2::text, ''), 'varchar(254)') THEN cb_ba2::VARCHAR(254) ELSE NULL END AS cb_ba2,
    CASE WHEN pg_input_is_valid(NULLIF(cb_bp1::text, ''), 'varchar(254)') THEN cb_bp1::VARCHAR(254) ELSE NULL END AS cb_bp1,
    CASE WHEN pg_input_is_valid(NULLIF(cb_bp2::text, ''), 'varchar(254)') THEN cb_bp2::VARCHAR(254) ELSE NULL END AS cb_bp2,
    CASE WHEN pg_input_is_valid(NULLIF(cb_cabphy::text, ''), 'varchar(254)') THEN cb_cabphy::VARCHAR(254) ELSE NULL END AS cb_cabphy,
    CASE WHEN pg_input_is_valid(NULLIF(cb_capafo::text, ''), 'integer') THEN cb_capafo::INTEGER ELSE NULL END AS cb_capafo,
    CASE WHEN pg_input_is_valid(NULLIF(cb_code::text, ''), 'varchar(254)') THEN cb_code::VARCHAR(254) ELSE NULL END AS cb_code,
    CASE WHEN pg_input_is_valid(NULLIF(cb_codeext::text, ''), 'varchar(254)') THEN cb_codeext::VARCHAR(254) ELSE NULL END AS cb_codeext,
    CASE WHEN pg_input_is_valid(NULLIF(cb_dateins::text, ''), 'date') THEN cb_dateins::DATE ELSE NULL END AS cb_dateins,
    CASE WHEN pg_input_is_valid(NULLIF(cb_etiquet::text, ''), 'varchar(254)') THEN cb_etiquet::VARCHAR(254) ELSE NULL END AS cb_etiquet,
    CASE WHEN pg_input_is_valid(NULLIF(cb_fo_disp::text, ''), 'integer') THEN cb_fo_disp::INTEGER ELSE NULL END AS cb_fo_disp,
    CASE WHEN pg_input_is_valid(NULLIF(cb_fo_type::text, ''), 'varchar(20)') THEN cb_fo_type::VARCHAR(20) ELSE NULL END AS cb_fo_type,
    CASE WHEN pg_input_is_valid(NULLIF(cb_fo_util::text, ''), 'integer') THEN cb_fo_util::INTEGER ELSE NULL END AS cb_fo_util,
    CASE WHEN pg_input_is_valid(NULLIF(cb_gest::text, ''), 'varchar(20)') THEN cb_gest::VARCHAR(20) ELSE NULL END AS cb_gest,
    CASE WHEN pg_input_is_valid(NULLIF(cb_lgreel::text, ''), 'numeric(7,2)') THEN cb_lgreel::NUMERIC(7,2) ELSE NULL END AS cb_lgreel,
    CASE WHEN pg_input_is_valid(NULLIF(cb_modulo::text, ''), 'integer') THEN cb_modulo::INTEGER ELSE NULL END AS cb_modulo,
    CASE WHEN pg_input_is_valid(NULLIF(cb_nd1::text, ''), 'varchar(254)') THEN cb_nd1::VARCHAR(254) ELSE NULL END AS cb_nd1,
    CASE WHEN pg_input_is_valid(NULLIF(cb_nd2::text, ''), 'varchar(254)') THEN cb_nd2::VARCHAR(254) ELSE NULL END AS cb_nd2,
    CASE WHEN pg_input_is_valid(NULLIF(cb_perirec::text, ''), 'varchar(254)') THEN cb_perirec::VARCHAR(254) ELSE NULL END AS cb_perirec,
    CASE WHEN pg_input_is_valid(NULLIF(cb_prop::text, ''), 'varchar(20)') THEN cb_prop::VARCHAR(20) ELSE NULL END AS cb_prop,
    CASE WHEN pg_input_is_valid(NULLIF(cb_proptyp::text, ''), 'varchar(3)') THEN cb_proptyp::VARCHAR(3) ELSE NULL END AS cb_proptyp,
    CASE WHEN pg_input_is_valid(NULLIF(cb_r1_code::text, ''), 'varchar(100)') THEN cb_r1_code::VARCHAR(100) ELSE NULL END AS cb_r1_code,
    CASE WHEN pg_input_is_valid(NULLIF(cb_r2_code::text, ''), 'varchar(100)') THEN cb_r2_code::VARCHAR(100) ELSE NULL END AS cb_r2_code,
    CASE WHEN pg_input_is_valid(NULLIF(cb_r3_code::text, ''), 'varchar(100)') THEN cb_r3_code::VARCHAR(100) ELSE NULL END AS cb_r3_code,
    CASE WHEN pg_input_is_valid(NULLIF(cb_rf_code::text, ''), 'varchar(254)') THEN cb_rf_code::VARCHAR(254) ELSE NULL END AS cb_rf_code,
    CASE WHEN pg_input_is_valid(NULLIF(cb_statut::text, ''), 'varchar(3)') THEN cb_statut::VARCHAR(3) ELSE NULL END AS cb_statut,
    CASE WHEN pg_input_is_valid(NULLIF(cb_typelog::text, ''), 'varchar(2)') THEN cb_typelog::VARCHAR(2) ELSE NULL END AS cb_typelog,
    CASE WHEN pg_input_is_valid(NULLIF(cb_typephy::text, ''), 'varchar(1)') THEN cb_typephy::VARCHAR(1) ELSE NULL END AS cb_typephy
FROM {{ source('gracethd', 't_cable') }}
