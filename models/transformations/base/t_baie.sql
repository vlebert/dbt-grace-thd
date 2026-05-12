{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['base'],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['ba_code'], 'type': 'btree'},
            {'columns': ['ba_etiquet'], 'type': 'btree'},
            {'columns': ['ba_prop'], 'type': 'btree'},
            {'columns': ['ba_gest'], 'type': 'btree'},
            {'columns': ['ba_proptyp'], 'type': 'btree'},
            {'columns': ['ba_statut'], 'type': 'btree'},
            {'columns': ['ba_rf_code'], 'type': 'btree'},
            {'columns': ['ba_type'], 'type': 'btree'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY ba_code) AS id,
    CASE WHEN pg_input_is_valid(NULLIF(ba_abandon::text, ''), 'varchar(1)') THEN ba_abandon::VARCHAR(1) ELSE NULL END AS ba_abandon,
    CASE WHEN pg_input_is_valid(NULLIF(ba_code::text, ''), 'varchar(254)') THEN ba_code::VARCHAR(254) ELSE NULL END AS ba_code,
    CASE WHEN pg_input_is_valid(NULLIF(ba_codeext::text, ''), 'varchar(254)') THEN ba_codeext::VARCHAR(254) ELSE NULL END AS ba_codeext,
    CASE WHEN pg_input_is_valid(NULLIF(ba_etiquet::text, ''), 'varchar(254)') THEN ba_etiquet::VARCHAR(254) ELSE NULL END AS ba_etiquet,
    CASE WHEN pg_input_is_valid(NULLIF(ba_gest::text, ''), 'varchar(20)') THEN ba_gest::VARCHAR(20) ELSE NULL END AS ba_gest,
    CASE WHEN pg_input_is_valid(NULLIF(ba_lc_code::text, ''), 'varchar(254)') THEN ba_lc_code::VARCHAR(254) ELSE NULL END AS ba_lc_code,
    CASE WHEN pg_input_is_valid(NULLIF(ba_nb_u::text, ''), 'numeric(5,2)') THEN ba_nb_u::NUMERIC(5,2) ELSE NULL END AS ba_nb_u,
    CASE WHEN pg_input_is_valid(NULLIF(ba_perirec::text, ''), 'varchar(254)') THEN ba_perirec::VARCHAR(254) ELSE NULL END AS ba_perirec,
    CASE WHEN pg_input_is_valid(NULLIF(ba_prop::text, ''), 'varchar(20)') THEN ba_prop::VARCHAR(20) ELSE NULL END AS ba_prop,
    CASE WHEN pg_input_is_valid(NULLIF(ba_proptyp::text, ''), 'varchar(3)') THEN ba_proptyp::VARCHAR(3) ELSE NULL END AS ba_proptyp,
    CASE WHEN pg_input_is_valid(NULLIF(ba_rf_code::text, ''), 'varchar(254)') THEN ba_rf_code::VARCHAR(254) ELSE NULL END AS ba_rf_code,
    CASE WHEN pg_input_is_valid(NULLIF(ba_statut::text, ''), 'varchar(3)') THEN ba_statut::VARCHAR(3) ELSE NULL END AS ba_statut,
    CASE WHEN pg_input_is_valid(NULLIF(ba_type::text, ''), 'varchar(10)') THEN ba_type::VARCHAR(10) ELSE NULL END AS ba_type
FROM {{ source('gracethd', 't_baie') }}
