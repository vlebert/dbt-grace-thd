{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['grace_thematiques', 'grace_capacite'],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['cb_code'], 'type': 'btree'},
            {'columns': ['bp_code'], 'type': 'btree'}
        ]
    )
}}

WITH destination AS (
    SELECT DISTINCT ON (rs.ropt_id)
        rs.ropt_id,
        rs.bp_code,
        r0.lc_code AS lc_code_start
    FROM {{ ref('ropt_section') }} rs
    LEFT JOIN {{ ref('ropt_section') }} r0
        ON r0.ropt_id = rs.ropt_id AND r0.ropt_ordr = 0
    WHERE rs.bp_typelog = 'PBO'
    ORDER BY rs.ropt_id, rs.ropt_ordr DESC
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
