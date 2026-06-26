{{
    config(
        pre_hook = [
            "ANALYZE {{ ref('ropt_section') }};"
        ],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['bp_code'], 'type': 'btree'}
        ]
    )
}}

-- Fibres distribuées par PBO : FIRST_VALUE(lc_code) évite un second scan de ropt_section
-- pour récupérer lc_code_start (était dans une CTE ropt_start séparée).
WITH ebp_fo_distrib AS (
    SELECT
        bp_code,
        COUNT(*) AS bp_nb_fo_distrib,
        SUM(CASE WHEN cb_typelog = 'RA' THEN 1 ELSE 0 END) AS bp_nb_fo_racco,
        MAX(lc_code_start) AS lc_code_start
    FROM (
        SELECT
            bp_code,
            cb_typelog,
            ps_fonct,
            FIRST_VALUE(lc_code) OVER (PARTITION BY ropt_id ORDER BY ropt_ordr) AS lc_code_start
        FROM {{ ref('ropt_section') }}
    ) sub
    WHERE (ps_fonct IN ('AT', 'MA') OR cb_typelog = 'RA')
      AND bp_code IS NOT NULL
    GROUP BY bp_code
),

-- Une seule zone SRO par lc_code : zs_lc_code n'est pas une clé unique dans t_zsro,
-- plusieurs zones peuvent référencer le même local (anomalie de saisie).
zsro_dedup AS (
    SELECT DISTINCT ON (zs_lc_code)
        zs_code,
        zs_lc_code
    FROM {{ ref('t_zsro') }}
    ORDER BY zs_lc_code, zs_code
)

SELECT
    bp.id,
    bp.bp_code,
    bp.bp_pt_code,
    bp.bp_perirec,
    bp.bp_etiquet,
    bp.bp_codeext,
    bp.bp_abandon,
    bp.bp_lc_code,
    bp.bp_prop,
    bp.bp_gest,
    bp.bp_proptyp,
    bp.bp_statut,
    bp.bp_dateins,
    bp.bp_avct,
    bp.bp_typephy,
    bp.bp_typelog,
    bp.bp_rf_code,
    COALESCE(z.bp_nb_loc, 0) AS bp_nb_loc,
    COALESCE(efd.bp_nb_fo_distrib, 0) AS bp_nb_fo_distrib,
    COALESCE(efd.bp_nb_fo_racco, 0) AS bp_nb_fo_racco,
    zs.zs_code,
    bp.geom
FROM {{ ref('elem_bp') }} bp
LEFT JOIN ebp_fo_distrib efd ON efd.bp_code = bp.bp_code
LEFT JOIN zsro_dedup zs ON zs.zs_lc_code = efd.lc_code_start
LEFT JOIN {{ ref('cap_zpbo') }} z ON z.bp_code = bp.bp_code
WHERE bp.bp_typelog = 'PBO'
