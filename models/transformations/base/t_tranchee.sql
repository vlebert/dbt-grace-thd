{{
    config(
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['tr_code'], 'type': 'btree'},
            {'columns': ['geom'], 'type': 'gist'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY tr_code)::int4 AS id,
    {{ safe_geom('MultiLineString') }} AS geom,
    CASE WHEN pg_input_is_valid(NULLIF(tr_code::text, ''), 'varchar(254)') THEN tr_code::VARCHAR(254) ELSE NULL END AS tr_code,
    CASE WHEN pg_input_is_valid(NULLIF(tr_compo::text, ''), 'varchar(254)') THEN tr_compo::VARCHAR(254) ELSE NULL END AS tr_compo,
    CASE WHEN pg_input_is_valid(NULLIF(tr_couptyp::text, ''), 'varchar(254)') THEN tr_couptyp::VARCHAR(254) ELSE NULL END AS tr_couptyp,
    CASE WHEN pg_input_is_valid(NULLIF(tr_dtclass::text, ''), 'varchar(2)') THEN tr_dtclass::VARCHAR(2) ELSE NULL END AS tr_dtclass,
    CASE WHEN pg_input_is_valid(NULLIF(tr_lgreel::text, ''), 'numeric(8,2)') THEN tr_lgreel::NUMERIC(8,2) ELSE NULL END AS tr_lgreel,
    CASE WHEN pg_input_is_valid(NULLIF(tr_pa1::text, ''), 'varchar(254)') THEN tr_pa1::VARCHAR(254) ELSE NULL END AS tr_pa1,
    CASE WHEN pg_input_is_valid(NULLIF(tr_pa2::text, ''), 'varchar(254)') THEN tr_pa2::VARCHAR(254) ELSE NULL END AS tr_pa2,
    CASE WHEN pg_input_is_valid(NULLIF(tr_perirec::text, ''), 'varchar(254)') THEN tr_perirec::VARCHAR(254) ELSE NULL END AS tr_perirec
FROM {{ source('gracethd', 't_tranchee') }}
