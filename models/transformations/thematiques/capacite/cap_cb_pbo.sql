{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['grace_thematiques', 'grace_capacite'],
        pre_hook = [
            "ANALYZE {{ ref('ropt_section') }};",
            "ANALYZE {{ ref('ropt') }};",
            "ANALYZE {{ ref('t_fibre') }};"
        ],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['cb_code'], 'type': 'btree'},
            {'columns': ['bp_code'], 'type': 'btree'}
        ]
    )
}}

-- Destination PBO de chaque ROPT : un seul GROUP BY sur ropt_section
-- au lieu d'une auto-jointure sur (ropt_id, ropt_ordr = 0).
WITH destination AS (
    SELECT ropt_id, bp_code, lc_code_start
    FROM (
        SELECT
            ropt_id,
            MAX(CASE WHEN ropt_ordr = 0 THEN lc_code END) AS lc_code_start,
            (ARRAY_AGG(bp_code ORDER BY ropt_ordr DESC) FILTER (WHERE bp_typelog = 'PBO'))[1] AS bp_code
        FROM {{ ref('ropt_section') }}
        GROUP BY ropt_id
    ) sub
    WHERE bp_code IS NOT NULL
)

SELECT
    ROW_NUMBER() OVER (ORDER BY cb.cb_code, ds.bp_code) AS id,
    cb.cb_code,
    cb.cb_capafo,
    ds.bp_code,
    MAX(pbo.bp_nb_loc) AS bp_nb_loc,
    MAX(pbo.bp_nb_fo_distrib) AS bp_nb_fo_distrib,
    MAX(pbo.bp_nb_fo_racco) AS bp_nb_fo_racco,
    COUNT(fo.fo_code) AS cb_nb_fo_distrib,
    MAX(zs.zs_code) AS zs_code,
    MAX(zs.zs_refpm) AS zs_refpm
FROM {{ ref('t_cable') }} cb
LEFT JOIN {{ ref('t_fibre') }} fo ON fo.fo_cb_code = cb.cb_code
LEFT JOIN {{ ref('ropt') }} r ON r.fo_code = fo.fo_code
LEFT JOIN destination ds ON ds.ropt_id = r.ropt_id
LEFT JOIN {{ ref('t_zsro') }} zs ON zs.zs_lc_code = ds.lc_code_start
LEFT JOIN {{ ref('cap_pbo') }} pbo ON pbo.bp_code = ds.bp_code
WHERE cb.cb_typelog = 'DI'
  AND ds.bp_code IS NOT NULL
GROUP BY cb.cb_code, cb.cb_capafo, ds.bp_code
