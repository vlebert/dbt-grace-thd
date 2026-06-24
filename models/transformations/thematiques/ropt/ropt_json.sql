{{
    config(
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['lc_code'], 'type': 'btree'}
        ]
    )
}}

-- Fiche JSON par local technique de départ : double niveau d'agrégation.
--   1. Une ligne par local technique amont (ropt_ordr = 0).
--   2. Pour chaque ligne, un tableau `json_data` de routes optiques ; chaque
--      route agrège l'ensemble de ses sections (ropt_section) pour un ropt_id,
--      enrichi de la synthèse PTO/PBO (adapté du legacy v_ropt_json, SQLite ->
--      PostgreSQL : json_group_array(json_object(...)) -> jsonb_agg(jsonb_build_object(...))).
WITH section AS (
    SELECT * FROM {{ ref('ropt_section') }}
),

-- Local technique de départ (ropt_ordr = 0) pour chaque route
depart AS (
    SELECT
        ropt_id,
        lc_code,
        lc_codeext,
        lc_typelog,
        lc_etage
    FROM section
    WHERE ropt_ordr = 0
),

-- Synthèse PTO par route
pto_info AS (
    SELECT
        ropt_id,
        MAX(bp_code) AS pto_bp_code,
        MAX(bp_codeext) AS pto_bp_codeext
    FROM section
    WHERE bp_typelog = 'PTO'
    GROUP BY ropt_id
),

-- Synthèse point de distribution (PBO) par route
pbo_info AS (
    SELECT
        ropt_id,
        MAX(bp_code) AS pbo_bp_code,
        MAX(bp_codeext) AS pbo_bp_codeext,
        MAX(cs_num) AS pbo_cs_num,
        MAX(ps_fonct) AS pbo_ps_fonct,
        MAX(ps_numero) AS pbo_ps_numero,
        MAX(ps_preaff) AS pbo_ps_preaff
    FROM section
    WHERE (ps_fonct IN ('AT', 'MA') OR cb_typelog = 'RA') AND bp_typelog = 'PBO'
    GROUP BY ropt_id
),

-- Une route optique = agrégation de ses sections + synthèse PTO/PBO
route AS (
    SELECT
        s.ropt_id,
        d.lc_code,
        d.lc_codeext,
        d.lc_typelog,
        d.lc_etage,
        jsonb_build_object(
            'ropt_id',             s.ropt_id,
            'ropt_pto_bp_code',    MAX(p.pto_bp_code),
            'ropt_pto_bp_codeext', MAX(p.pto_bp_codeext),
            'ropt_pbo_bp_code',    MAX(e.pbo_bp_code),
            'ropt_pbo_bp_codeext', MAX(e.pbo_bp_codeext),
            'ropt_pbo_cs_num',     MAX(e.pbo_cs_num),
            'ropt_pbo_ps_fonct',   MAX(e.pbo_ps_fonct),
            'ropt_pbo_ps_numero',  MAX(e.pbo_ps_numero),
            'ropt_pbo_ps_preaff',  MAX(e.pbo_ps_preaff),
            'sections', jsonb_agg(
                jsonb_build_object(
                    'ropt_ordr',  s.ropt_ordr,
                    -- Informations du noeud
                    'lc_code',    s.lc_code,
                    'lc_codeext', s.lc_codeext,
                    'lc_typelog', s.lc_typelog,
                    'lc_etage',   s.lc_etage,
                    'bp_codeext', s.bp_codeext,
                    'bp_typelog', s.bp_typelog,
                    'pt_code',    s.pt_code,
                    'pt_codeext', s.pt_codeext,
                    'pt_typephy', s.pt_typephy,
                    'pt_nature',  s.pt_nature,
                    'ti_codeext', s.ti_codeext,
                    'cs_num',     s.cs_num,
                    'ps_numero',  s.ps_numero,
                    'ps_fonct',   s.ps_fonct,
                    'ps_preaff',  s.ps_preaff,
                    -- Informations du lien
                    'cb_codeext', s.cb_codeext,
                    'cb_capafo',  s.cb_capafo,
                    'fo_numtub',  s.fo_numtub,
                    'fo_nintub',  s.fo_nintub,
                    'cb_lgreel',  s.cb_lgreel,
                    'bp_code',    s.bp_code,
                    'cb_typelog', s.cb_typelog
                )
                ORDER BY s.ropt_ordr
            )
        ) AS route_json
    FROM section s
    LEFT JOIN depart d ON s.ropt_id = d.ropt_id
    LEFT JOIN pto_info p ON s.ropt_id = p.ropt_id
    LEFT JOIN pbo_info e ON s.ropt_id = e.ropt_id
    GROUP BY s.ropt_id, d.lc_code, d.lc_codeext, d.lc_typelog, d.lc_etage
)

SELECT
    row_number() OVER (ORDER BY lc_code)::int4 AS id,
    lc_code,
    lc_codeext,
    lc_typelog,
    lc_etage,
    jsonb_agg(route_json ORDER BY ropt_id) AS json_data
FROM route
GROUP BY lc_code, lc_codeext, lc_typelog, lc_etage
