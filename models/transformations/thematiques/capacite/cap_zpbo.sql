{{
    config(
        materialized = 'table',
        pre_hook = [
            "ANALYZE {{ ref('ropt_section') }};",
            "ANALYZE {{ ref('elem_lc_st_nd') }};"
        ],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['bp_code'], 'type': 'btree'},
            {'columns': ['geom'], 'type': 'gist'}
        ]
    )
}}

-- Zone d'influence d'un PBO : locaux desservis (raccordés sinon préaffectés)
-- et étoile géométrique reliant le PBO à chacun de ses locaux.

-- PBO de raccordement = bp_code de l'étape précédente dans la route optique.
-- LAG calculé sur la route COMPLÈTE, AVANT toute jointure/filtre, pour ne pas
-- amputer la fenêtre : les étapes intermédiaires (PBO traversés) ont souvent
-- lc_code NULL, seul le local en extrémité (ropt_ordr max) le renseigne.
WITH ropt_prev AS (
    SELECT
        lc_code,
        LAG(bp_code) OVER (PARTITION BY ropt_id ORDER BY ropt_ordr) AS bp_raccorde
    FROM {{ ref('ropt_section') }}
),

-- Un local = un PBO : raccordé prioritaire, sinon préaffectation (lc_bp_codf).
loc_pbo AS (
    SELECT DISTINCT ON (lc.lc_code)
        lc.lc_code,
        COALESCE(rp.bp_raccorde, lc.lc_bp_codf) AS bp_code,
        lc.geom AS lc_geom
    FROM {{ ref('elem_lc_st_nd') }} lc
    LEFT JOIN ropt_prev rp ON rp.lc_code = lc.lc_code
    WHERE COALESCE(rp.bp_raccorde, lc.lc_bp_codf) IS NOT NULL
    ORDER BY lc.lc_code, rp.bp_raccorde NULLS LAST  -- privilégie le raccordé
),

-- Point unique par PBO (elem_bp peut faire du fan-out).
pbo_pt AS (
    SELECT DISTINCT ON (bp_code) bp_code, geom
    FROM {{ ref('elem_bp') }}
    WHERE geom IS NOT NULL
    ORDER BY bp_code
)

SELECT
    row_number() OVER (ORDER BY lp.bp_code)::int4 AS id,
    lp.bp_code,
    COUNT(*) AS bp_nb_loc,
    string_agg(lp.lc_code, ',' ORDER BY lp.lc_code) AS lc_codes,
    ST_Collect(ST_MakeLine(ST_Centroid(pt.geom), ST_Centroid(lp.lc_geom)))
        FILTER (WHERE pt.geom IS NOT NULL AND lp.lc_geom IS NOT NULL) AS geom
FROM loc_pbo lp
LEFT JOIN pbo_pt pt ON pt.bp_code = lp.bp_code
GROUP BY lp.bp_code
