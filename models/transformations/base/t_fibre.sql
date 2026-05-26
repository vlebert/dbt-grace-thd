{{
    config(
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['fo_code'], 'type': 'btree'},
            {'columns': ['fo_cb_code'], 'type': 'btree'},
            {'columns': ['fo_etat'], 'type': 'btree'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY fo_code) AS id,
    CASE WHEN pg_input_is_valid(NULLIF(fo_cb_code::text, ''), 'varchar(254)') THEN fo_cb_code::VARCHAR(254) ELSE NULL END AS fo_cb_code,
    CASE WHEN pg_input_is_valid(NULLIF(fo_code::text, ''), 'varchar(254)') THEN fo_code::VARCHAR(254) ELSE NULL END AS fo_code,
    CASE WHEN pg_input_is_valid(NULLIF(fo_etat::text, ''), 'varchar(3)') THEN fo_etat::VARCHAR(3) ELSE NULL END AS fo_etat,
    CASE WHEN pg_input_is_valid(NULLIF(fo_nincab::text, ''), 'integer') THEN fo_nincab::INTEGER ELSE NULL END AS fo_nincab,
    CASE WHEN pg_input_is_valid(NULLIF(fo_nintub::text, ''), 'integer') THEN fo_nintub::INTEGER ELSE NULL END AS fo_nintub,
    CASE WHEN pg_input_is_valid(NULLIF(fo_numtub::text, ''), 'integer') THEN fo_numtub::INTEGER ELSE NULL END AS fo_numtub
FROM {{ source('gracethd', 't_fibre') }}
