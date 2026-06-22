{{
    config(
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['bp_code'], 'type': 'btree'},
            {'columns': ['geom'], 'type': 'gist'}
        ]
    )
}}

-- Fiche JSON par PBO : agrège, pour chaque point de branchement, l'ensemble de
-- ses cassettes, positions, et les deux fibres/câbles raccordés sur chaque
-- position (ps_1 / ps_2). Adapté du legacy v_json_pdb (SQLite) :
--   json_group_array(json_object(...)) -> jsonb_agg(jsonb_build_object(...)).
-- Les fibres/câbles sont joints deux fois (couple 1 et 2 de chaque position),
-- d'où les alias fo1/cb1 et fo2/cb2 sur t_fibre / t_cable.
WITH detail AS (
    SELECT
        bp.bp_code,
        bp.bp_codeext,
        bp.bp_typelog,
        bp.geom,
        jsonb_build_object(
            'ps_code',       ps.ps_code,
            'ps_fonct',      ps.ps_fonct,
            'ps_numero',     ps.ps_numero,
            'ps_1',          ps.ps_1,
            'ps_2',          ps.ps_2,
            'fo1_fo_nintub', fo1.fo_nintub,
            'fo1_fo_numtub', fo1.fo_numtub,
            'cb1_code',      cb1.cb_code,
            'cb1_codeext',   cb1.cb_codeext,
            'cb1_capafo',    cb1.cb_capafo,
            'fo2_fo_nintub', fo2.fo_nintub,
            'fo2_fo_numtub', fo2.fo_numtub,
            'cb2_code',      cb2.cb_code,
            'cb2_codeext',   cb2.cb_codeext,
            'cb2_capafo',    cb2.cb_capafo,
            'cs_code',       cs.cs_code,
            'cs_bp_code',    cs.cs_bp_code,
            'cs_num',        cs.cs_num,
            'bp_code',       bp.bp_code,
            'bp_codeext',    bp.bp_codeext,
            'bp_typelog',    bp.bp_typelog
        ) AS position_json,
        cs.cs_num,
        ps.ps_numero
    FROM {{ ref('elem_bp') }} AS bp
    LEFT JOIN {{ ref('elem_cs') }} AS cs
        ON cs.cs_bp_code = bp.bp_code
    LEFT JOIN {{ ref('elem_ps') }} AS ps
        ON ps.ps_cs_code = cs.cs_code
    LEFT JOIN {{ ref('t_fibre') }} AS fo1
        ON ps.ps_1 = fo1.fo_code
    LEFT JOIN {{ ref('t_fibre') }} AS fo2
        ON ps.ps_2 = fo2.fo_code
    LEFT JOIN {{ ref('t_cable') }} AS cb1
        ON fo1.fo_cb_code = cb1.cb_code
    LEFT JOIN {{ ref('t_cable') }} AS cb2
        ON fo2.fo_cb_code = cb2.cb_code
    WHERE bp.bp_typelog IN ('PBO', 'BPE')
)

SELECT
    row_number() OVER (ORDER BY bp_code)::int4 AS id,
    bp_code,
    bp_codeext,
    bp_typelog,
    jsonb_agg(position_json ORDER BY cs_num, ps_numero) AS json_data,
    geom
FROM detail
GROUP BY bp_code, bp_codeext, bp_typelog, geom
