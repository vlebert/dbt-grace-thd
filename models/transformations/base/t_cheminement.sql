{{
    config(
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['cm_code'], 'type': 'btree'},
            {'columns': ['geom'], 'type': 'gist'},
            {'columns': ['cm_ndcode1'], 'type': 'btree'},
            {'columns': ['cm_ndcode2'], 'type': 'btree'},
            {'columns': ['cm_gest'], 'type': 'btree'},
            {'columns': ['cm_prop'], 'type': 'btree'},
            {'columns': ['cm_statut'], 'type': 'btree'},
            {'columns': ['cm_avct'], 'type': 'btree'},
            {'columns': ['cm_typelog'], 'type': 'btree'},
            {'columns': ['cm_typ_imp'], 'type': 'btree'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY cm_code) AS id,
    CASE WHEN pg_input_is_valid(NULLIF(cm_avct::text, ''), 'varchar(1)') THEN cm_avct::VARCHAR(1) ELSE NULL END AS cm_avct,
    CASE WHEN pg_input_is_valid(NULLIF(cm_code::text, ''), 'varchar(254)') THEN cm_code::VARCHAR(254) ELSE NULL END AS cm_code,
    CASE WHEN pg_input_is_valid(NULLIF(cm_compo::text, ''), 'varchar(254)') THEN cm_compo::VARCHAR(254) ELSE NULL END AS cm_compo,
    CASE WHEN pg_input_is_valid(NULLIF(cm_gest::text, ''), 'varchar(20)') THEN cm_gest::VARCHAR(20) ELSE NULL END AS cm_gest,
    CASE WHEN pg_input_is_valid(NULLIF(cm_ndcode1::text, ''), 'varchar(254)') THEN cm_ndcode1::VARCHAR(254) ELSE NULL END AS cm_ndcode1,
    CASE WHEN pg_input_is_valid(NULLIF(cm_ndcode2::text, ''), 'varchar(254)') THEN cm_ndcode2::VARCHAR(254) ELSE NULL END AS cm_ndcode2,
    CASE WHEN pg_input_is_valid(NULLIF(cm_perirec::text, ''), 'varchar(254)') THEN cm_perirec::VARCHAR(254) ELSE NULL END AS cm_perirec,
    CASE WHEN pg_input_is_valid(NULLIF(cm_prop::text, ''), 'varchar(20)') THEN cm_prop::VARCHAR(20) ELSE NULL END AS cm_prop,
    CASE WHEN pg_input_is_valid(NULLIF(cm_statut::text, ''), 'varchar(3)') THEN cm_statut::VARCHAR(3) ELSE NULL END AS cm_statut,
    CASE WHEN pg_input_is_valid(NULLIF(cm_typ_imp::text, ''), 'varchar(2)') THEN cm_typ_imp::VARCHAR(2) ELSE NULL END AS cm_typ_imp,
    CASE WHEN pg_input_is_valid(NULLIF(cm_typelog::text, ''), 'varchar(2)') THEN cm_typelog::VARCHAR(2) ELSE NULL END AS cm_typelog,
    geom AS geom
FROM {{ source('gracethd', 't_cheminement') }}
