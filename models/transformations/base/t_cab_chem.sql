{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['base'],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['cc_cb_code', 'cc_cm_code'], 'type': 'btree'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY cc_cb_code) AS id,
    CASE WHEN pg_input_is_valid(NULLIF(cc_cb_code::text, ''), 'varchar(254)') THEN cc_cb_code::VARCHAR(254) ELSE NULL END AS cc_cb_code,
    CASE WHEN pg_input_is_valid(NULLIF(cc_cm_code::text, ''), 'varchar(254)') THEN cc_cm_code::VARCHAR(254) ELSE NULL END AS cc_cm_code
FROM {{ source('gracethd', 't_cab_chem') }}
