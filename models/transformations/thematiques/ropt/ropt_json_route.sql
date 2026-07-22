{{
    config(
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['lc_code'], 'type': 'btree'},
            {'columns': ['ropt_id'], 'type': 'btree'}
        ]
    )
}}

-- Fiche JSON à la maille route optique : une ligne par ropt_id.
--   * Les attributs du local technique de départ (ropt_ordr = 0) et la synthèse
--     PTO/PBO sont exposés en colonnes, directement exploitables en SIG.
--   * La colonne `json_data` porte l'objet route complet (mêmes attributs +
--     sous-tableau `sections` trié par ropt_ordr), pré-construit une fois pour
--     toutes afin que l'agrégation par local technique (`ropt_json`) n'ait plus
--     qu'à concaténer des objets JSONB déjà bâtis.
--
-- La route se calcule en une seule passe groupée par ropt_id via l'agrégation
-- conditionnelle (FILTER), évitant de rebalayer/joindre ropt_section pour
-- chaque synthèse.
WITH section AS (
    SELECT
        *,
        -- Prédicat point de distribution (PBO) pré-calculé
        ((ps_fonct IN ('AT', 'MA') OR cb_typelog = 'RA') AND bp_typelog = 'PBO') AS is_pbo
    FROM {{ ref('ropt_section') }}
),

-- Une route optique = attributs de départ + synthèse PTO/PBO + ses sections
route AS (
    SELECT
        s.ropt_id,
        -- Local technique de départ
        MAX(s.lc_code)    FILTER (WHERE s.ropt_ordr = 0) AS lc_code,
        MAX(s.lc_codeext) FILTER (WHERE s.ropt_ordr = 0) AS lc_codeext,
        MAX(s.lc_etiquet) FILTER (WHERE s.ropt_ordr = 0) AS lc_etiquet,
        MAX(s.lc_typelog) FILTER (WHERE s.ropt_ordr = 0) AS lc_typelog,
        MAX(s.lc_etage)   FILTER (WHERE s.ropt_ordr = 0) AS lc_etage,
        -- Synthèse PTO
        MAX(s.bp_code)    FILTER (WHERE s.bp_typelog = 'PTO') AS ropt_pto_bp_code,
        MAX(s.bp_codeext) FILTER (WHERE s.bp_typelog = 'PTO') AS ropt_pto_bp_codeext,
        MAX(s.bp_etiquet) FILTER (WHERE s.bp_typelog = 'PTO') AS ropt_pto_bp_etiquet,
        -- Synthèse PBO
        MAX(s.bp_code)    FILTER (WHERE s.is_pbo) AS ropt_pbo_bp_code,
        MAX(s.bp_codeext) FILTER (WHERE s.is_pbo) AS ropt_pbo_bp_codeext,
        MAX(s.bp_etiquet) FILTER (WHERE s.is_pbo) AS ropt_pbo_bp_etiquet,
        MAX(s.cs_num)     FILTER (WHERE s.is_pbo) AS ropt_pbo_cs_num,
        MAX(s.ps_fonct)   FILTER (WHERE s.is_pbo) AS ropt_pbo_ps_fonct,
        MAX(s.ps_numero)  FILTER (WHERE s.is_pbo) AS ropt_pbo_ps_numero,
        MAX(s.ps_preaff)  FILTER (WHERE s.is_pbo) AS ropt_pbo_ps_preaff,
        -- Étapes de la route
        jsonb_agg(
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
        ) AS sections
    FROM section s
    GROUP BY s.ropt_id
)

SELECT
    row_number() OVER ()::int4 AS id,
    ropt_id,
    lc_code,
    lc_codeext,
    lc_etiquet,
    lc_typelog,
    lc_etage,
    ropt_pto_bp_code,
    ropt_pto_bp_codeext,
    ropt_pto_bp_etiquet,
    ropt_pbo_bp_code,
    ropt_pbo_bp_codeext,
    ropt_pbo_bp_etiquet,
    ropt_pbo_cs_num,
    ropt_pbo_ps_fonct,
    ropt_pbo_ps_numero,
    ropt_pbo_ps_preaff,
    jsonb_build_object(
        'ropt_id',             ropt_id,
        'ropt_pto_bp_code',    ropt_pto_bp_code,
        'ropt_pto_bp_codeext', ropt_pto_bp_codeext,
        'ropt_pto_bp_etiquet', ropt_pto_bp_etiquet,
        'ropt_pbo_bp_code',    ropt_pbo_bp_code,
        'ropt_pbo_bp_codeext', ropt_pbo_bp_codeext,
        'ropt_pbo_bp_etiquet', ropt_pbo_bp_etiquet,
        'ropt_pbo_cs_num',     ropt_pbo_cs_num,
        'ropt_pbo_ps_fonct',   ropt_pbo_ps_fonct,
        'ropt_pbo_ps_numero',  ropt_pbo_ps_numero,
        'ropt_pbo_ps_preaff',  ropt_pbo_ps_preaff,
        'sections',            sections
    ) AS json_data
FROM route
