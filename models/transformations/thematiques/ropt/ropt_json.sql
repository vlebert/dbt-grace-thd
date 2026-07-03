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
--
-- La route (départ + synthèses PTO/PBO + sections) se calcule en une seule
-- passe groupée par ropt_id via l'agrégation conditionnelle (FILTER), évitant
-- de rebalayer/joindre ropt_section pour chaque synthèse.
WITH section AS (
    SELECT
        *,
        -- Prédicat point de distribution (PBO) pré-calculé
        ((ps_fonct IN ('AT', 'MA') OR cb_typelog = 'RA') AND bp_typelog = 'PBO') AS is_pbo
    FROM {{ ref('ropt_section') }}
),

-- Une route optique = agrégation de ses sections + synthèse PTO/PBO (1 ligne / ropt_id)
route AS (
    SELECT
        s.ropt_id,
        MAX(s.lc_code)    FILTER (WHERE s.ropt_ordr = 0) AS lc_code,
        MAX(s.lc_codeext) FILTER (WHERE s.ropt_ordr = 0) AS lc_codeext,
        MAX(s.lc_etiquet) FILTER (WHERE s.ropt_ordr = 0) AS lc_etiquet,
        MAX(s.lc_typelog) FILTER (WHERE s.ropt_ordr = 0) AS lc_typelog,
        MAX(s.lc_etage)   FILTER (WHERE s.ropt_ordr = 0) AS lc_etage,
        jsonb_build_object(
            'ropt_id',             s.ropt_id,
            'ropt_pto_bp_code',    MAX(s.bp_code)    FILTER (WHERE s.bp_typelog = 'PTO'),
            'ropt_pto_bp_codeext', MAX(s.bp_codeext) FILTER (WHERE s.bp_typelog = 'PTO'),
            'ropt_pto_bp_etiquet', MAX(s.bp_etiquet) FILTER (WHERE s.bp_typelog = 'PTO'),
            'ropt_pbo_bp_code',    MAX(s.bp_code)    FILTER (WHERE s.is_pbo),
            'ropt_pbo_bp_codeext', MAX(s.bp_codeext) FILTER (WHERE s.is_pbo),
            'ropt_pbo_bp_etiquet', MAX(s.bp_etiquet) FILTER (WHERE s.is_pbo),
            'ropt_pbo_cs_num',     MAX(s.cs_num)     FILTER (WHERE s.is_pbo),
            'ropt_pbo_ps_fonct',   MAX(s.ps_fonct)   FILTER (WHERE s.is_pbo),
            'ropt_pbo_ps_numero',  MAX(s.ps_numero)  FILTER (WHERE s.is_pbo),
            'ropt_pbo_ps_preaff',  MAX(s.ps_preaff)  FILTER (WHERE s.is_pbo),
            'sections', jsonb_agg(
                jsonb_build_object(
                    'ropt_ordr',  s.ropt_ordr,
                    -- Informations du noeud
                    'lc_code',    s.lc_code,
                    'lc_codeext', s.lc_codeext,
                    'lc_etiquet', s.lc_etiquet,
                    'lc_typelog', s.lc_typelog,
                    'lc_etage',   s.lc_etage,
                    'bp_codeext', s.bp_codeext,
                    'bp_etiquet', s.bp_etiquet,
                    'bp_typelog', s.bp_typelog,
                    'pt_code',    s.pt_code,
                    'pt_codeext', s.pt_codeext,
                    'pt_etiquet', s.pt_etiquet,
                    'pt_typephy', s.pt_typephy,
                    'pt_nature',  s.pt_nature,
                    'ti_codeext', s.ti_codeext,
                    'ti_etiquet', s.ti_etiquet,
                    'cs_num',     s.cs_num,
                    'ps_numero',  s.ps_numero,
                    'ps_fonct',   s.ps_fonct,
                    'ps_preaff',  s.ps_preaff,
                    -- Informations du lien
                    'cb_codeext', s.cb_codeext,
                    'cb_etiquet', s.cb_etiquet,
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
    GROUP BY s.ropt_id
)

SELECT
    row_number() OVER (ORDER BY lc_code)::int4 AS id,
    lc_code,
    MAX(lc_codeext) AS lc_codeext,
    MAX(lc_etiquet) AS lc_etiquet,
    MAX(lc_typelog) AS lc_typelog,
    MAX(lc_etage)   AS lc_etage,
    jsonb_agg(route_json ORDER BY ropt_id) AS json_data
FROM route
GROUP BY lc_code
