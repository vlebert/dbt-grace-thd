{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['grace_thematiques', 'grace_capacite'],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['bp_code'], 'type': 'btree'}
        ]
    )
}}

WITH ropt_start AS (
    SELECT ropt_id, lc_code AS lc_code_start
    FROM {{ ref('ropt_section') }}
    WHERE ropt_ordr = 0
),

ebp_fo_distrib AS (
    SELECT
        rs.bp_code,
        COUNT(*) AS bp_nb_fo_distrib,
        SUM(CASE WHEN rs.cb_typelog = 'RA' THEN 1 ELSE 0 END) AS bp_nb_fo_racco,
        MAX(zs.zs_code) AS zs_code
    FROM {{ ref('ropt_section') }} rs
    LEFT JOIN ropt_start r0 ON r0.ropt_id = rs.ropt_id
    LEFT JOIN {{ ref('t_zsro') }} zs ON zs.zs_lc_code = r0.lc_code_start
    WHERE (rs.ps_fonct IN ('AT', 'MA') OR rs.cb_typelog = 'RA')
      AND rs.bp_code IS NOT NULL
    GROUP BY rs.bp_code
),

loc_par_pbo AS (
    SELECT
        COALESCE(rs_prev.bp_code, lc.lc_bp_codf) AS bp_code,
        COUNT(*) AS bp_nb_loc
    FROM {{ ref('t_local') }} lc
    LEFT JOIN {{ ref('ropt_section') }} rs ON rs.lc_code = lc.lc_code
    LEFT JOIN {{ ref('ropt_section') }} rs_prev
        ON rs_prev.ropt_id = rs.ropt_id
        AND rs_prev.ropt_ordr = rs.ropt_ordr - 1
    WHERE COALESCE(rs_prev.bp_code, lc.lc_bp_codf) IS NOT NULL
    GROUP BY COALESCE(rs_prev.bp_code, lc.lc_bp_codf)
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
    COALESCE(loc.bp_nb_loc, 0) AS bp_nb_loc,
    COALESCE(efd.bp_nb_fo_distrib, 0) AS bp_nb_fo_distrib,
    COALESCE(efd.bp_nb_fo_racco, 0) AS bp_nb_fo_racco,
    efd.zs_code,
    bp.geom
FROM {{ ref('elem_bp') }} bp
LEFT JOIN ebp_fo_distrib efd ON efd.bp_code = bp.bp_code
LEFT JOIN loc_par_pbo loc ON loc.bp_code = bp.bp_code
WHERE bp.bp_typelog = 'PBO'
