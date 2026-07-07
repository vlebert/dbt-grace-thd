{{
    config(
        materialized = 'table',
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['bp_code'], 'type': 'btree'},
            {'columns': ['bp_pt_code'], 'type': 'btree'},
            {'columns': ['bp_prop'], 'type': 'btree'},
            {'columns': ['bp_gest'], 'type': 'btree'},
            {'columns': ['bp_proptyp'], 'type': 'btree'},
            {'columns': ['bp_statut'], 'type': 'btree'},
            {'columns': ['bp_avct'], 'type': 'btree'},
            {'columns': ['bp_rf_code'], 'type': 'btree'},
            {'columns': ['geom'], 'type': 'gist'}
        ]
    )
}}

-- Matérialisé en table : les LEFT JOIN sur des codes non contraints en base
-- peuvent provoquer un fan-out et dupliquer l'`id` issu de t_ebp. L'`id` est
-- régénéré via row_number() pour garantir une clé primaire unique non bloquante.
-- Les index reproduisent ceux de la table base t_ebp (+ gist sur geom).
SELECT
  row_number() OVER (ORDER BY bp.bp_code)::int4 AS id,
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
  COALESCE(nd1.geom, nd2.geom) AS geom
FROM {{ ref('t_ebp') }} AS bp
LEFT JOIN {{ ref('t_ptech') }} AS pt
  ON bp.bp_pt_code = pt.pt_code
LEFT JOIN {{ ref('t_noeud') }} AS nd1
  ON pt.pt_nd_code = nd1.nd_code
LEFT JOIN {{ ref('t_local') }} AS lc
  ON bp.bp_lc_code = lc.lc_code
LEFT JOIN {{ ref('t_site') }} AS st
  ON lc.lc_st_code = st.st_code
LEFT JOIN {{ ref('t_noeud') }} AS nd2
  ON st.st_nd_code = nd2.nd_code
WHERE bp.bp_typelog IN ('PBO', 'BPE', 'BPI')
