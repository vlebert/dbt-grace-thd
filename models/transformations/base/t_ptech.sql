{{
    config(
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['pt_code'], 'type': 'btree'},
            {'columns': ['pt_nd_code'], 'type': 'btree'},
            {'columns': ['pt_prop'], 'type': 'btree'},
            {'columns': ['pt_gest'], 'type': 'btree'},
            {'columns': ['pt_statut'], 'type': 'btree'},
            {'columns': ['pt_avct'], 'type': 'btree'},
            {'columns': ['pt_typephy'], 'type': 'btree'},
            {'columns': ['pt_nature'], 'type': 'btree'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY pt_code) AS id,
    CASE WHEN pg_input_is_valid(NULLIF(pt_a_haut::text, ''), 'numeric(5,2)') THEN pt_a_haut::NUMERIC(5,2) ELSE NULL END AS pt_a_haut,
    CASE WHEN pg_input_is_valid(NULLIF(pt_a_struc::text, ''), 'varchar(100)') THEN pt_a_struc::VARCHAR(100) ELSE NULL END AS pt_a_struc,
    CASE WHEN pg_input_is_valid(NULLIF(pt_abandon::text, ''), 'varchar(1)') THEN pt_abandon::VARCHAR(1) ELSE NULL END AS pt_abandon,
    CASE WHEN pg_input_is_valid(NULLIF(pt_avct::text, ''), 'varchar(1)') THEN pt_avct::VARCHAR(1) ELSE NULL END AS pt_avct,
    CASE WHEN pg_input_is_valid(NULLIF(pt_code::text, ''), 'varchar(254)') THEN pt_code::VARCHAR(254) ELSE NULL END AS pt_code,
    CASE WHEN pg_input_is_valid(NULLIF(pt_codeext::text, ''), 'varchar(254)') THEN pt_codeext::VARCHAR(254) ELSE NULL END AS pt_codeext,
    CASE WHEN pg_input_is_valid(NULLIF(pt_etiquet::text, ''), 'varchar(254)') THEN pt_etiquet::VARCHAR(254) ELSE NULL END AS pt_etiquet,
    CASE WHEN pg_input_is_valid(NULLIF(pt_gest::text, ''), 'varchar(20)') THEN pt_gest::VARCHAR(20) ELSE NULL END AS pt_gest,
    CASE WHEN pg_input_is_valid(NULLIF(pt_nature::text, ''), 'varchar(20)') THEN pt_nature::VARCHAR(20) ELSE NULL END AS pt_nature,
    CASE WHEN pg_input_is_valid(NULLIF(pt_nd_code::text, ''), 'varchar(254)') THEN pt_nd_code::VARCHAR(254) ELSE NULL END AS pt_nd_code,
    CASE WHEN pg_input_is_valid(NULLIF(pt_perirec::text, ''), 'varchar(254)') THEN pt_perirec::VARCHAR(254) ELSE NULL END AS pt_perirec,
    CASE WHEN pg_input_is_valid(NULLIF(pt_prop::text, ''), 'varchar(20)') THEN pt_prop::VARCHAR(20) ELSE NULL END AS pt_prop,
    CASE WHEN pg_input_is_valid(NULLIF(pt_proptyp::text, ''), 'varchar(3)') THEN pt_proptyp::VARCHAR(3) ELSE NULL END AS pt_proptyp,
    CASE WHEN pg_input_is_valid(NULLIF(pt_secu::text, ''), 'varchar(1)') THEN pt_secu::VARCHAR(1) ELSE NULL END AS pt_secu,
    CASE WHEN pg_input_is_valid(NULLIF(pt_statut::text, ''), 'varchar(3)') THEN pt_statut::VARCHAR(3) ELSE NULL END AS pt_statut,
    CASE WHEN pg_input_is_valid(NULLIF(pt_typephy::text, ''), 'varchar(1)') THEN pt_typephy::VARCHAR(1) ELSE NULL END AS pt_typephy
FROM {{ source('gracethd', 't_ptech') }}
