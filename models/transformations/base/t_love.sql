{{
    config(
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['lv_id'], 'type': 'btree'}
        ]
    )
}}

SELECT
    row_number() OVER (ORDER BY lv_id) AS id,
    CASE WHEN pg_input_is_valid(NULLIF(lv_cb_code::text, ''), 'varchar(254)') THEN lv_cb_code::VARCHAR(254) ELSE NULL END AS lv_cb_code,
    CASE WHEN pg_input_is_valid(NULLIF(lv_id::text, ''), 'bigint') THEN lv_id::BIGINT ELSE NULL END AS lv_id,
    CASE WHEN pg_input_is_valid(NULLIF(lv_long::text, ''), 'integer') THEN lv_long::INTEGER ELSE NULL END AS lv_long,
    CASE WHEN pg_input_is_valid(NULLIF(lv_nd_code::text, ''), 'varchar(254)') THEN lv_nd_code::VARCHAR(254) ELSE NULL END AS lv_nd_code
FROM {{ source('gracethd', 't_love') }}
