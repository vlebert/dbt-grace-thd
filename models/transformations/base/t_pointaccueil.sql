{{
    config(
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['pa_code'], 'type': 'btree'},
            {'columns': ['geom'], 'type': 'gist'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY pa_code)::int4 AS id,
    {{ safe_geom('MultiPoint') }} AS geom,
    CASE WHEN pg_input_is_valid(NULLIF(pa_a_haut::text, ''), 'numeric(5,2)') THEN pa_a_haut::NUMERIC(5,2) ELSE NULL END AS pa_a_haut,
    CASE WHEN pg_input_is_valid(NULLIF(pa_a_struc::text, ''), 'varchar(100)') THEN pa_a_struc::VARCHAR(100) ELSE NULL END AS pa_a_struc,
    CASE WHEN pg_input_is_valid(NULLIF(pa_code::text, ''), 'varchar(254)') THEN pa_code::VARCHAR(254) ELSE NULL END AS pa_code,
    CASE WHEN pg_input_is_valid(NULLIF(pa_codeext::text, ''), 'varchar(254)') THEN pa_codeext::VARCHAR(254) ELSE NULL END AS pa_codeext,
    CASE WHEN pg_input_is_valid(NULLIF(pa_codtemp::text, ''), 'varchar(254)') THEN pa_codtemp::VARCHAR(254) ELSE NULL END AS pa_codtemp,
    CASE WHEN pg_input_is_valid(NULLIF(pa_datecon::text, ''), 'date') THEN pa_datecon::DATE ELSE NULL END AS pa_datecon,
    CASE WHEN pg_input_is_valid(NULLIF(pa_dtclass::text, ''), 'varchar(2)') THEN pa_dtclass::VARCHAR(2) ELSE NULL END AS pa_dtclass,
    CASE WHEN pg_input_is_valid(NULLIF(pa_gest::text, ''), 'varchar(20)') THEN pa_gest::VARCHAR(20) ELSE NULL END AS pa_gest,
    CASE WHEN pg_input_is_valid(NULLIF(pa_nature::text, ''), 'varchar(20)') THEN pa_nature::VARCHAR(20) ELSE NULL END AS pa_nature,
    CASE WHEN pg_input_is_valid(NULLIF(pa_perirec::text, ''), 'varchar(254)') THEN pa_perirec::VARCHAR(254) ELSE NULL END AS pa_perirec,
    CASE WHEN pg_input_is_valid(NULLIF(pa_prop::text, ''), 'varchar(20)') THEN pa_prop::VARCHAR(20) ELSE NULL END AS pa_prop,
    CASE WHEN pg_input_is_valid(NULLIF(pa_rotatio::text, ''), 'numeric(5,2)') THEN pa_rotatio::NUMERIC(5,2) ELSE NULL END AS pa_rotatio,
    CASE WHEN pg_input_is_valid(NULLIF(pa_secu::text, ''), 'varchar(1)') THEN pa_secu::VARCHAR(1) ELSE NULL END AS pa_secu,
    CASE WHEN pg_input_is_valid(NULLIF(pa_typephy::text, ''), 'varchar(3)') THEN pa_typephy::VARCHAR(3) ELSE NULL END AS pa_typephy
FROM {{ source('gracethd', 't_pointaccueil') }}
