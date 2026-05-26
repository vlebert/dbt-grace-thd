{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['grace_thematiques', 'grace_capacite'],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['cb_code'], 'type': 'btree'}
        ]
    )
}}

WITH cb_stats AS (
    SELECT
        cb_code,
        MAX(zs_code) AS zs_code,
        MAX(zs_refpm) AS zs_refpm,
        SUM(bp_nb_loc) AS cb_nb_loc,
        SUM(bp_nb_fo_distrib) AS cb_nb_fo_distrib,
        SUM(bp_nb_fo_racco) AS cb_nb_fo_racco,
        STRING_AGG(DISTINCT bp_code, ',') AS destinations
    FROM {{ ref('cap_cb_pbo') }}
    WHERE bp_code IS NOT NULL
    GROUP BY cb_code
)

SELECT
    ROW_NUMBER() OVER (ORDER BY cb.cb_code) AS id,
    cb.cb_code,
    cb.cb_codeext,
    cb.cb_abandon,
    cb.cb_perirec,
    cb.cb_etiquet,
    cb.cb_nd1,
    cb.cb_nd2,
    cb.cb_bp1,
    cb.cb_ba1,
    cb.cb_bp2,
    cb.cb_ba2,
    cb.cb_r1_code,
    cb.cb_r2_code,
    cb.cb_r3_code,
    cb.cb_fo_type,
    cb.cb_prop,
    cb.cb_gest,
    cb.cb_proptyp,
    cb.cb_statut,
    cb.cb_dateins,
    cb.cb_avct,
    cb.cb_typephy,
    cb.cb_typelog,
    cb.cb_rf_code,
    cb.cb_capafo,
    cb.cb_fo_disp,
    cb.cb_fo_util,
    cb.cb_modulo,
    cb.cb_cabphy,
    cb.cb_lgreel,
    stats.zs_code,
    stats.zs_refpm,
    stats.cb_nb_loc,
    stats.cb_nb_fo_distrib,
    stats.cb_nb_fo_racco,
    stats.destinations,
    cb.geom
FROM {{ ref('elem_cb') }} cb
LEFT JOIN cb_stats stats ON stats.cb_code = cb.cb_code
WHERE cb.cb_typelog = 'DI'
