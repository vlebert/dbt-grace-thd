{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['thematiques', 'ropt'],
        pre_hook = [
            "ANALYZE {{ ref('t_position') }};",
            "ANALYZE {{ ref('t_fibre') }};",
            "ANALYZE {{ ref('t_cable') }};",
            "ANALYZE {{ ref('t_cassette') }};",
            "ANALYZE {{ ref('t_tiroir') }};",
            "ANALYZE {{ ref('t_baie') }};",
            "ANALYZE {{ ref('t_local') }};",
            "ANALYZE {{ ref('t_ebp') }};",
            "ANALYZE {{ ref('t_site') }};",
            "ANALYZE {{ ref('t_ptech') }};"
        ],
        indexes = [
            {'columns': ['ropt_id'], 'type': 'btree'}
        ]
    )
}}

WITH RECURSIVE ropt AS (
    -- Ancre: positions dans tiroirs avec câbles DI ou TR/CT en locaux NRO
    SELECT
        ROW_NUMBER() OVER () AS ropt_id,
        0 AS ropt_ordr,
        {{ ref('t_position') }}.ps_2 AS fo_code,
        {{ ref('t_position') }}.ps_code AS ps_amont,
        {{ ref('t_cable') }}.cb_typelog AS ropt_typelog
    FROM {{ ref('t_position') }}
    -- LEFT JOIN {{ ref('t_cassette') }} ON cs_code = {{ ref('t_position') }}.ps_cs_code
    LEFT JOIN {{ ref('t_fibre') }} ON ({{ ref('t_position') }}.ps_2 = {{ ref('t_fibre') }}.fo_code OR {{ ref('t_position') }}.ps_1 = {{ ref('t_fibre') }}.fo_code)
    LEFT JOIN {{ ref('t_cable') }} ON {{ ref('t_cable') }}.cb_code = {{ ref('t_fibre') }}.fo_cb_code
    LEFT JOIN {{ ref('t_tiroir') }} ON {{ ref('t_tiroir') }}.ti_code = {{ ref('t_position') }}.ps_ti_code
    LEFT JOIN {{ ref('t_baie') }} ON {{ ref('t_baie') }}.ba_code = {{ ref('t_tiroir') }}.ti_ba_code
    LEFT JOIN {{ ref('t_local') }} ON {{ ref('t_local') }}.lc_code = {{ ref('t_baie') }}.ba_lc_code
    WHERE {{ ref('t_position') }}.ps_ti_code IS NOT NULL
      AND (
          {{ ref('t_cable') }}.cb_typelog = 'DI'
          OR ({{ ref('t_cable') }}.cb_typelog IN ('TR', 'CT') AND {{ ref('t_local') }}.lc_typelog = 'NRO')
      )

    UNION ALL

    -- Partie récursive: suit le chemin via ps_1/ps_2 <-> fo_code
    SELECT
        r.ropt_id,
        r.ropt_ordr + 1,
        CASE
            WHEN r.fo_code = p.ps_1 THEN p.ps_2
            WHEN r.fo_code = p.ps_2 THEN p.ps_1
            ELSE NULL
        END AS fo_code,
        p.ps_code AS ps_amont,
        r.ropt_typelog
    FROM ropt r
    CROSS JOIN LATERAL (
        SELECT ps_1, ps_2, ps_code
        FROM {{ ref('t_position') }} p
        WHERE (p.ps_1 = r.fo_code OR p.ps_2 = r.fo_code)
          AND p.ps_code <> r.ps_amont
        LIMIT 1
    ) p
    WHERE r.ropt_ordr < 22
)

SELECT
    -- ROW_NUMBER() OVER () AS id,
    ropt_id,
    ropt_ordr,
    fo_code,
    ps_amont,
    ropt_typelog
FROM ropt
ORDER BY ropt_id, ropt_ordr
