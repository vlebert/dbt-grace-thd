{{
    config(
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['or_code'], 'type': 'btree'},
            {'columns': ['or_nom'], 'type': 'btree'},
            {'columns': ['or_siret'], 'type': 'btree'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY or_code) AS id,
    CASE WHEN pg_input_is_valid(NULLIF(or_code::text, ''), 'varchar(20)') THEN or_code::VARCHAR(20) ELSE NULL END AS or_code,
    CASE WHEN pg_input_is_valid(NULLIF(or_commune::text, ''), 'varchar(254)') THEN or_commune::VARCHAR(254) ELSE NULL END AS or_commune,
    CASE WHEN pg_input_is_valid(NULLIF(or_local::text, ''), 'varchar(254)') THEN or_local::VARCHAR(254) ELSE NULL END AS or_local,
    CASE WHEN pg_input_is_valid(NULLIF(or_nom::text, ''), 'varchar(254)') THEN or_nom::VARCHAR(254) ELSE NULL END AS or_nom,
    CASE WHEN pg_input_is_valid(NULLIF(or_nomvoie::text, ''), 'varchar(254)') THEN or_nomvoie::VARCHAR(254) ELSE NULL END AS or_nomvoie,
    CASE WHEN pg_input_is_valid(NULLIF(or_numero::text, ''), 'integer') THEN or_numero::INTEGER ELSE NULL END AS or_numero,
    CASE WHEN pg_input_is_valid(NULLIF(or_postal::text, ''), 'varchar(20)') THEN or_postal::VARCHAR(20) ELSE NULL END AS or_postal,
    CASE WHEN pg_input_is_valid(NULLIF(or_rep::text, ''), 'varchar(20)') THEN or_rep::VARCHAR(20) ELSE NULL END AS or_rep,
    CASE WHEN pg_input_is_valid(NULLIF(or_siret::text, ''), 'varchar(14)') THEN or_siret::VARCHAR(14) ELSE NULL END AS or_siret,
    CASE WHEN pg_input_is_valid(NULLIF(or_type::text, ''), 'varchar(254)') THEN or_type::VARCHAR(254) ELSE NULL END AS or_type
FROM {{ source('gracethd', 't_organisme') }}
