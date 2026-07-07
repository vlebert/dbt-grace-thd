{{
    config(
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['zs_code'], 'type': 'btree'},
            {'columns': ['geom'], 'type': 'gist'}
        ]
    )
}}

-- Synoptique par zone SRO (zs_code) au format graphe Cytoscape. Adapté du legacy
-- `v_syno_cytoscape` (SQLite) vers PostgreSQL :
--   json_object(...)                    -> jsonb_build_object(...)
--   GROUP_CONCAT(DISTINCT json_object)  -> jsonb_agg(...) sur des noeuds dédupliqués
--
-- Une ligne par zone porte une unique colonne `json_data` directement
-- consommable par Cytoscape (`elements`), de la forme :
--   { "nodes": [ {"data": {...}}, ... ], "edges": [ {"data": {...}}, ... ] }
--   * nodes : points de branchement (PBO) et local technique (SRO) ;
--   * edges : câbles de distribution reliant ces éléments.
--
-- Les extrémités boîtier sont résolues sur TOUS les boîtiers (`elem_bp`), pas
-- seulement les PBO : un câble abouti sur un BPE (ou un boîtier PM) reste ainsi
-- une extrémité connue (sinon source/target basculent à tort sur NULL). Les
-- compteurs de capacité sont rattachés en LEFT JOIN via `cap_pbo` (nuls hors PBO).
-- Reproduit la CTE `ebp` du legacy (vs_elem_bp + t_ebp_fo_distrib).
WITH ebp AS (
    SELECT
        bp.bp_code,
        bp.bp_codeext,
        bp.bp_etiquet,
        bp.bp_typelog,
        cap.bp_nb_loc,
        cap.bp_nb_fo_distrib,
        cap.bp_nb_fo_racco
    FROM {{ ref('elem_bp') }} bp
    LEFT JOIN {{ ref('cap_pbo') }} cap ON cap.bp_code = bp.bp_code
),

cable_data AS (
    SELECT
        cb.cb_code,
        cb.cb_codeext,
        cb.cb_etiquet,
        cb.cb_capafo,
        cb.cb_nb_loc,
        cb.cb_nb_fo_distrib,
        cb.cb_nb_fo_racco,
        cb.zs_code,
        bp1.bp_code           AS bp1_code,
        bp1.bp_codeext        AS bp1_codeext,
        bp1.bp_etiquet        AS bp1_etiquet,
        bp1.bp_typelog        AS bp1_typelog,
        bp1.bp_nb_fo_racco    AS bp1_nb_fo_racco,
        bp1.bp_nb_fo_distrib  AS bp1_nb_fo_distrib,
        bp1.bp_nb_loc         AS bp1_nb_loc,
        bp2.bp_code           AS bp2_code,
        bp2.bp_codeext        AS bp2_codeext,
        bp2.bp_etiquet        AS bp2_etiquet,
        bp2.bp_typelog        AS bp2_typelog,
        bp2.bp_nb_fo_racco    AS bp2_nb_fo_racco,
        bp2.bp_nb_fo_distrib  AS bp2_nb_fo_distrib,
        bp2.bp_nb_loc         AS bp2_nb_loc,
        COALESCE(lt1.lc_code, lt2.lc_code)       AS lt_code,
        COALESCE(lt1.lc_codeext, lt2.lc_codeext) AS lt_codeext,
        COALESCE(lt1.lc_etiquet, lt2.lc_etiquet) AS lt_etiquet,
        COALESCE(st1.st_code, st2.st_code)       AS st_code,
        COALESCE(st1.st_codeext, st2.st_codeext) AS st_codeext
    FROM {{ ref('cap_cb') }} cb
    LEFT JOIN ebp bp1 ON cb.cb_bp1 = bp1.bp_code
    LEFT JOIN ebp bp2 ON cb.cb_bp2 = bp2.bp_code
    LEFT JOIN {{ ref('t_baie') }} ba1  ON cb.cb_ba1 = ba1.ba_code
    LEFT JOIN {{ ref('t_baie') }} ba2  ON cb.cb_ba2 = ba2.ba_code
    LEFT JOIN {{ ref('t_local') }} lt1 ON ba1.ba_lc_code = lt1.lc_code
    LEFT JOIN {{ ref('t_local') }} lt2 ON ba2.ba_lc_code = lt2.lc_code
    LEFT JOIN {{ ref('t_site') }} st1  ON lt1.lc_st_code = st1.st_code
    LEFT JOIN {{ ref('t_site') }} st2  ON lt2.lc_st_code = st2.st_code
    WHERE cb.zs_code IS NOT NULL
),

-- Noeuds : boîtier d'extrémité 1 (PBO/BPE), boîtier d'extrémité 2, et local technique (SRO).
-- (zs_code, node_id, data) : node_id porté à part pour dédoublonner sur l'identifiant.
node_rows AS (
    SELECT
        zs_code,
        bp1_code AS node_id,
        jsonb_build_object(
            'data', jsonb_build_object(
                'id', bp1_code,
                'label', bp1_etiquet,
                'properties', jsonb_build_object(
                    'bp_code', bp1_code,
                    'bp_codeext', bp1_codeext,
                    'bp_etiquet', bp1_etiquet,
                    'bp_typelog', bp1_typelog,
                    'bp_nb_fo_racco', bp1_nb_fo_racco,
                    'bp_nb_fo_distrib', bp1_nb_fo_distrib,
                    'bp_nb_loc', bp1_nb_loc
                )
            )
        ) AS data
    FROM cable_data
    WHERE bp1_code IS NOT NULL

    UNION ALL

    SELECT
        zs_code,
        bp2_code,
        jsonb_build_object(
            'data', jsonb_build_object(
                'id', bp2_code,
                'label', bp2_etiquet,
                'properties', jsonb_build_object(
                    'bp_code', bp2_code,
                    'bp_codeext', bp2_codeext,
                    'bp_etiquet', bp2_etiquet,
                    'bp_typelog', bp2_typelog,
                    'bp_nb_fo_racco', bp2_nb_fo_racco,
                    'bp_nb_fo_distrib', bp2_nb_fo_distrib,
                    'bp_nb_loc', bp2_nb_loc
                )
            )
        )
    FROM cable_data
    WHERE bp2_code IS NOT NULL

    UNION ALL

    SELECT
        zs_code,
        lt_code,
        jsonb_build_object(
            'data', jsonb_build_object(
                'id', lt_code,
                'label', lt_etiquet,
                'properties', jsonb_build_object(
                    'lt_code', lt_code,
                    'lt_codeext', lt_codeext,
                    'lt_etiquet', lt_etiquet,
                    'st_code', st_code,
                    'st_codeext', st_codeext
                )
            )
        )
    FROM cable_data
    WHERE lt_code IS NOT NULL
),

-- Un noeud par (zone, id) : garantit des identifiants uniques côté Cytoscape.
nodes_dedup AS (
    SELECT DISTINCT ON (zs_code, node_id)
        zs_code,
        data
    FROM node_rows
    ORDER BY zs_code, node_id
),

-- Arêtes : un câble de distribution = un lien orienté source -> cible.
edges AS (
    SELECT
        zs_code,
        jsonb_build_object(
            'data', jsonb_build_object(
                'source', COALESCE(bp1_code, lt_code),
                'target', COALESCE(bp2_code, lt_code),
                'label', cb_etiquet || chr(10) || cb_capafo || ' FO',
                'properties', jsonb_build_object(
                    'cb_code', cb_code,
                    'cb_codeext', cb_codeext,
                    'cb_etiquet', cb_etiquet,
                    'cb_capafo', cb_capafo,
                    'cb_nb_loc', cb_nb_loc,
                    'cb_nb_fo_distrib', cb_nb_fo_distrib,
                    'cb_nb_fo_racco', cb_nb_fo_racco
                )
            )
        ) AS data
    FROM cable_data
),

node_agg AS (
    SELECT zs_code, jsonb_agg(data) AS nodes
    FROM nodes_dedup
    GROUP BY zs_code
),

edge_agg AS (
    SELECT zs_code, jsonb_agg(data) AS edges
    FROM edges
    GROUP BY zs_code
),

-- zs_code n'est pas garanti unique dans t_zsro : on dédoublonne pour préserver
-- l'unicité de la clé primaire régénérée.
zsro AS (
    SELECT DISTINCT ON (zs_code)
        zs_code,
        geom
    FROM {{ ref('t_zsro') }}
    WHERE zs_code IS NOT NULL
    ORDER BY zs_code, id
)

SELECT
    row_number() OVER (ORDER BY n.zs_code)::int4 AS id,
    n.zs_code,
    jsonb_build_object(
        'nodes', n.nodes,
        'edges', COALESCE(e.edges, '[]'::jsonb)
    ) AS json_data,
    zs.geom
FROM node_agg n
LEFT JOIN edge_agg e ON n.zs_code = e.zs_code
LEFT JOIN zsro zs ON zs.zs_code = n.zs_code
