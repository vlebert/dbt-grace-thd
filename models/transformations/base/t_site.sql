{{
    config(
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['st_code'], 'type': 'btree'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY st_code) AS id,
    CASE WHEN pg_input_is_valid(NULLIF(st_abandon::text, ''), 'varchar(1)') THEN st_abandon::VARCHAR(1) ELSE NULL END AS st_abandon,
    CASE WHEN pg_input_is_valid(NULLIF(st_ad_code::text, ''), 'varchar(254)') THEN st_ad_code::VARCHAR(254) ELSE NULL END AS st_ad_code,
    CASE WHEN pg_input_is_valid(NULLIF(st_avct::text, ''), 'varchar(1)') THEN st_avct::VARCHAR(1) ELSE NULL END AS st_avct,
    CASE WHEN pg_input_is_valid(NULLIF(st_code::text, ''), 'varchar(254)') THEN st_code::VARCHAR(254) ELSE NULL END AS st_code,
    CASE WHEN pg_input_is_valid(NULLIF(st_codeext::text, ''), 'varchar(254)') THEN st_codeext::VARCHAR(254) ELSE NULL END AS st_codeext,
    CASE WHEN pg_input_is_valid(NULLIF(st_commune::text, ''), 'varchar(254)') THEN st_commune::VARCHAR(254) ELSE NULL END AS st_commune,
    CASE WHEN pg_input_is_valid(NULLIF(st_dateins::text, ''), 'date') THEN st_dateins::DATE ELSE NULL END AS st_dateins,
    CASE WHEN pg_input_is_valid(NULLIF(st_design::text, ''), 'varchar(254)') THEN st_design::VARCHAR(254) ELSE NULL END AS st_design,
    CASE WHEN pg_input_is_valid(NULLIF(st_gest::text, ''), 'varchar(20)') THEN st_gest::VARCHAR(20) ELSE NULL END AS st_gest,
    CASE WHEN pg_input_is_valid(NULLIF(st_insee::text, ''), 'varchar(20)') THEN st_insee::VARCHAR(20) ELSE NULL END AS st_insee,
    CASE WHEN pg_input_is_valid(NULLIF(st_nd_code::text, ''), 'varchar(254)') THEN st_nd_code::VARCHAR(254) ELSE NULL END AS st_nd_code,
    CASE WHEN pg_input_is_valid(NULLIF(st_nombat::text, ''), 'varchar(254)') THEN st_nombat::VARCHAR(254) ELSE NULL END AS st_nombat,
    CASE WHEN pg_input_is_valid(NULLIF(st_nomvoie::text, ''), 'varchar(254)') THEN st_nomvoie::VARCHAR(254) ELSE NULL END AS st_nomvoie,
    CASE WHEN pg_input_is_valid(NULLIF(st_nra::text, ''), 'varchar(1)') THEN st_nra::VARCHAR(1) ELSE NULL END AS st_nra,
    CASE WHEN pg_input_is_valid(NULLIF(st_numero::text, ''), 'integer') THEN st_numero::INTEGER ELSE NULL END AS st_numero,
    CASE WHEN pg_input_is_valid(NULLIF(st_perirec::text, ''), 'varchar(254)') THEN st_perirec::VARCHAR(254) ELSE NULL END AS st_perirec,
    CASE WHEN pg_input_is_valid(NULLIF(st_postal::text, ''), 'varchar(254)') THEN st_postal::VARCHAR(254) ELSE NULL END AS st_postal,
    CASE WHEN pg_input_is_valid(NULLIF(st_prop::text, ''), 'varchar(20)') THEN st_prop::VARCHAR(20) ELSE NULL END AS st_prop,
    CASE WHEN pg_input_is_valid(NULLIF(st_proptyp::text, ''), 'varchar(3)') THEN st_proptyp::VARCHAR(3) ELSE NULL END AS st_proptyp,
    CASE WHEN pg_input_is_valid(NULLIF(st_rep::text, ''), 'varchar(20)') THEN st_rep::VARCHAR(20) ELSE NULL END AS st_rep,
    CASE WHEN pg_input_is_valid(NULLIF(st_statut::text, ''), 'varchar(3)') THEN st_statut::VARCHAR(3) ELSE NULL END AS st_statut,
    CASE WHEN pg_input_is_valid(NULLIF(st_typelog::text, ''), 'varchar(10)') THEN st_typelog::VARCHAR(10) ELSE NULL END AS st_typelog,
    CASE WHEN pg_input_is_valid(NULLIF(st_typephy::text, ''), 'varchar(3)') THEN st_typephy::VARCHAR(3) ELSE NULL END AS st_typephy
FROM {{ source('gracethd', 't_site') }}
