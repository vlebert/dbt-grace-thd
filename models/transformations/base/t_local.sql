{{
    config(
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['lc_code'], 'type': 'btree'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY lc_code) AS id,
    CASE WHEN pg_input_is_valid(NULLIF(lc_abandon::text, ''), 'varchar(1)') THEN lc_abandon::VARCHAR(1) ELSE NULL END AS lc_abandon,
    CASE WHEN pg_input_is_valid(NULLIF(lc_avct::text, ''), 'varchar(1)') THEN lc_avct::VARCHAR(1) ELSE NULL END AS lc_avct,
    CASE WHEN pg_input_is_valid(NULLIF(lc_bat::text, ''), 'varchar(100)') THEN lc_bat::VARCHAR(100) ELSE NULL END AS lc_bat,
    CASE WHEN pg_input_is_valid(NULLIF(lc_bp_codf::text, ''), 'varchar(254)') THEN lc_bp_codf::VARCHAR(254) ELSE NULL END AS lc_bp_codf,
    CASE WHEN pg_input_is_valid(NULLIF(lc_bp_codp::text, ''), 'varchar(254)') THEN lc_bp_codp::VARCHAR(254) ELSE NULL END AS lc_bp_codp,
    CASE WHEN pg_input_is_valid(NULLIF(lc_code::text, ''), 'varchar(254)') THEN lc_code::VARCHAR(254) ELSE NULL END AS lc_code,
    CASE WHEN pg_input_is_valid(NULLIF(lc_codeext::text, ''), 'varchar(254)') THEN lc_codeext::VARCHAR(254) ELSE NULL END AS lc_codeext,
    CASE WHEN pg_input_is_valid(NULLIF(lc_dateins::text, ''), 'date') THEN lc_dateins::DATE ELSE NULL END AS lc_dateins,
    CASE WHEN pg_input_is_valid(NULLIF(lc_elec::text, ''), 'varchar(1)') THEN lc_elec::VARCHAR(1) ELSE NULL END AS lc_elec,
    CASE WHEN pg_input_is_valid(NULLIF(lc_escal::text, ''), 'varchar(20)') THEN lc_escal::VARCHAR(20) ELSE NULL END AS lc_escal,
    CASE WHEN pg_input_is_valid(NULLIF(lc_etage::text, ''), 'varchar(20)') THEN lc_etage::VARCHAR(20) ELSE NULL END AS lc_etage,
    CASE WHEN pg_input_is_valid(NULLIF(lc_etiquet::text, ''), 'varchar(20)') THEN lc_etiquet::VARCHAR(20) ELSE NULL END AS lc_etiquet,
    CASE WHEN pg_input_is_valid(NULLIF(lc_gest::text, ''), 'varchar(20)') THEN lc_gest::VARCHAR(20) ELSE NULL END AS lc_gest,
    CASE WHEN pg_input_is_valid(NULLIF(lc_perirec::text, ''), 'varchar(254)') THEN lc_perirec::VARCHAR(254) ELSE NULL END AS lc_perirec,
    CASE WHEN pg_input_is_valid(NULLIF(lc_prop::text, ''), 'varchar(20)') THEN lc_prop::VARCHAR(20) ELSE NULL END AS lc_prop,
    CASE WHEN pg_input_is_valid(NULLIF(lc_proptyp::text, ''), 'varchar(3)') THEN lc_proptyp::VARCHAR(3) ELSE NULL END AS lc_proptyp,
    CASE WHEN pg_input_is_valid(NULLIF(lc_st_code::text, ''), 'varchar(254)') THEN lc_st_code::VARCHAR(254) ELSE NULL END AS lc_st_code,
    CASE WHEN pg_input_is_valid(NULLIF(lc_statut::text, ''), 'varchar(3)') THEN lc_statut::VARCHAR(3) ELSE NULL END AS lc_statut,
    CASE WHEN pg_input_is_valid(NULLIF(lc_typelog::text, ''), 'varchar(10)') THEN lc_typelog::VARCHAR(10) ELSE NULL END AS lc_typelog
FROM {{ source('gracethd', 't_local') }}
