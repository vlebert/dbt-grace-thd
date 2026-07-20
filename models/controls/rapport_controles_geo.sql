{{
  config(
    tags=['grace_rapport'],
    post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
    indexes = [
      {'columns': ['geom'], 'type': 'gist'},
      {'columns': ['type_controle'], 'type': 'btree'}
    ]
  )
}}

{#
  Rapport consolidé géolocalisé.

  Enrichit `rapport_controles` d'une colonne `geom` en résolvant par
  (classe, id_entite). Chaque classe connue a sa stratégie de résolution
  explicite basée sur les vues élémentaires du projet.

  Stratégies :
    - Direct : table a une colonne geom (t_adresse, t_noeud, t_cableline, etc.)
    - Via t_noeud : jointure chaînée jusqu'à t_noeud (t_baie, t_site, t_ptech, etc.)
    - Via t_cableline : t_cable → t_cableline, t_fibre → t_cable → t_cableline
    - COALESCE : pour les classes avec plusieurs chemins possibles (t_ebp, t_position)
    - NULL : classes sans géométrie (t_organisme, t_reference, etc.)

  Pour ajouter une nouvelle classe : ajouter une branche UNION ALL avec la
  stratégie adaptée.
#}

with rapport_geo as (

-- Placeholder : schéma stable même si rapport_controles est vide
-- (id::int4 pour aligner avec r.* qui porte désormais la clé de rapport_controles)
select
  null::int4     as id,
  null::text     as id_test,
  null::text     as type_controle,
  null::text     as description,
  null::text     as classe,
  null::text     as attribut,
  null::text     as id_entite,
  null::text     as detail_erreur,
  null::geometry as geom
where false

-- ============================================================
-- 1. CLASSES AVEC GEOMETRIE DIRECTE
-- ============================================================

-- t_adresse
union all
select r.*, t.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_adresse') }} t on t.ad_code = r.id_entite
where r.classe = 't_adresse'

-- t_cableline
union all
select r.*, t.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_cableline') }} t on t.cl_code = r.id_entite
where r.classe = 't_cableline'

-- t_cheminement
union all
select r.*, t.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_cheminement') }} t on t.cm_code = r.id_entite
where r.classe = 't_cheminement'

-- t_noeud
union all
select r.*, t.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_noeud') }} t on t.nd_code = r.id_entite
where r.classe = 't_noeud'

-- t_pointaccueil
union all
select r.*, t.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_pointaccueil') }} t on t.pa_code = r.id_entite
where r.classe = 't_pointaccueil'

-- t_point_leve
union all
select r.*, t.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_point_leve') }} t on t.pl_code = r.id_entite
where r.classe = 't_point_leve'

-- t_tranchee
union all
select r.*, t.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_tranchee') }} t on t.tr_code = r.id_entite
where r.classe = 't_tranchee'

-- t_znro
union all
select r.*, t.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_znro') }} t on t.zn_code = r.id_entite
where r.classe = 't_znro'

-- t_zsro
union all
select r.*, t.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_zsro') }} t on t.zs_code = r.id_entite
where r.classe = 't_zsro'

-- t_zdep
union all
select r.*, t.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_zdep') }} t on t.zd_code = r.id_entite
where r.classe = 't_zdep'

-- ============================================================
-- 2. CLASSES AVEC HERITAGE VIA t_noeud (jointure directe : xx_code = nd_code)
--    Selon les vues élémentaires, certaines tables ont leur code qui EST
--    le nd_code (ex: ba_code = nd_code pour les baies-partagées)
-- ============================================================

-- Note: En réalité, d'après les sources YAML, ces tables n'ont PAS de
-- colonne geom directement. La stratégie "xx_code = nd_code" n'est PAS
-- validée par le schéma. On utilise donc les jointures chaînées.

-- ============================================================
-- 3. CLASSES AVEC HERITAGE VIA t_noeud (jointures chaînées)
-- ============================================================

-- t_ptech : pt_nd_code → t_noeud
union all
select r.*, n.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_ptech') }} t on t.pt_code = r.id_entite
left join {{ source('gracethd', 't_noeud') }} n on n.nd_code = t.pt_nd_code
where r.classe = 't_ptech'

-- t_site : st_nd_code → t_noeud
union all
select r.*, n.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_site') }} t on t.st_code = r.id_entite
left join {{ source('gracethd', 't_noeud') }} n on n.nd_code = t.st_nd_code
where r.classe = 't_site'

-- t_local : lc_st_code → t_site → st_nd_code → t_noeud
union all
select r.*, n.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_local') }} lc on lc.lc_code = r.id_entite
left join {{ source('gracethd', 't_site') }} st on st.st_code = lc.lc_st_code
left join {{ source('gracethd', 't_noeud') }} n on n.nd_code = st.st_nd_code
where r.classe = 't_local'

-- t_baie : ba_lc_code → t_local → lc_st_code → t_site → st_nd_code → t_noeud
union all
select r.*, n.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_baie') }} ba on ba.ba_code = r.id_entite
left join {{ source('gracethd', 't_local') }} lc on lc.lc_code = ba.ba_lc_code
left join {{ source('gracethd', 't_site') }} st on st.st_code = lc.lc_st_code
left join {{ source('gracethd', 't_noeud') }} n on n.nd_code = st.st_nd_code
where r.classe = 't_baie'

-- t_tiroir : ti_ba_code → t_baie → ba_lc_code → t_local → lc_st_code → t_site → st_nd_code → t_noeud
union all
select r.*, n.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_tiroir') }} ti on ti.ti_code = r.id_entite
left join {{ source('gracethd', 't_baie') }} ba on ba.ba_code = ti.ti_ba_code
left join {{ source('gracethd', 't_local') }} lc on lc.lc_code = ba.ba_lc_code
left join {{ source('gracethd', 't_site') }} st on st.st_code = lc.lc_st_code
left join {{ source('gracethd', 't_noeud') }} n on n.nd_code = st.st_nd_code
where r.classe = 't_tiroir'

-- t_ebp : DEUX CHEMINS POSSIBLES (selon elem_bp.sql)
--   Chemin 1: bp_pt_code → t_ptech → pt_nd_code → t_noeud
--   Chemin 2: bp_lc_code → t_local → lc_st_code → t_site → st_nd_code → t_noeud
union all
select r.*, COALESCE(nd_pt.geom, nd_lc.geom) as geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_ebp') }} bp on bp.bp_code = r.id_entite
-- Chemin 1: via t_ptech
left join {{ source('gracethd', 't_ptech') }} pt on pt.pt_code = bp.bp_pt_code
left join {{ source('gracethd', 't_noeud') }} nd_pt on nd_pt.nd_code = pt.pt_nd_code
-- Chemin 2: via t_local → t_site
left join {{ source('gracethd', 't_local') }} lc on lc.lc_code = bp.bp_lc_code
left join {{ source('gracethd', 't_site') }} st on st.st_code = lc.lc_st_code
left join {{ source('gracethd', 't_noeud') }} nd_lc on nd_lc.nd_code = st.st_nd_code
where r.classe = 't_ebp'

-- t_cassette : cs_bp_code → t_ebp → DEUX CHEMINS (comme t_ebp)
--   Chemin 1: bp_pt_code → t_ptech → pt_nd_code → t_noeud
--   Chemin 2: bp_lc_code → t_local → lc_st_code → t_site → st_nd_code → t_noeud
union all
select r.*, COALESCE(nd_pt.geom, nd_lc.geom) as geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_cassette') }} cs on cs.cs_code = r.id_entite
left join {{ source('gracethd', 't_ebp') }} bp on bp.bp_code = cs.cs_bp_code
-- Chemin 1: via t_ptech
left join {{ source('gracethd', 't_ptech') }} pt on pt.pt_code = bp.bp_pt_code
left join {{ source('gracethd', 't_noeud') }} nd_pt on nd_pt.nd_code = pt.pt_nd_code
-- Chemin 2: via t_local → t_site
left join {{ source('gracethd', 't_local') }} lc on lc.lc_code = bp.bp_lc_code
left join {{ source('gracethd', 't_site') }} st on st.st_code = lc.lc_st_code
left join {{ source('gracethd', 't_noeud') }} nd_lc on nd_lc.nd_code = st.st_nd_code
where r.classe = 't_cassette'

-- t_position : DEUX CHEMINS POSSIBLES (selon elem_ps_cs.sql et elem_ps_ti.sql)
--   Chemin 1: ps_cs_code → t_cassette → cs_bp_code → t_ebp → ...
--   Chemin 2: ps_ti_code → t_tiroir → ti_ba_code → t_baie → ...
union all
select r.*, COALESCE(nd_cs.geom, nd_ti.geom) as geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_position') }} ps on ps.ps_code = r.id_entite
-- Chemin 1: via t_cassette → t_ebp → t_ptech → t_noeud
left join {{ source('gracethd', 't_cassette') }} cs on cs.cs_code = ps.ps_cs_code
left join {{ source('gracethd', 't_ebp') }} bp1 on bp1.bp_code = cs.cs_bp_code
left join {{ source('gracethd', 't_ptech') }} pt1 on pt1.pt_code = bp1.bp_pt_code
left join {{ source('gracethd', 't_noeud') }} nd1 on nd1.nd_code = pt1.pt_nd_code
left join {{ source('gracethd', 't_local') }} lc1 on lc1.lc_code = bp1.bp_lc_code
left join {{ source('gracethd', 't_site') }} st1 on st1.st_code = lc1.lc_st_code
left join {{ source('gracethd', 't_noeud') }} nd_cs on nd_cs.nd_code = st1.st_nd_code
-- Chemin 2: via t_tiroir → t_baie → t_local → t_site → t_noeud
left join {{ source('gracethd', 't_tiroir') }} ti on ti.ti_code = ps.ps_ti_code
left join {{ source('gracethd', 't_baie') }} ba on ba.ba_code = ti.ti_ba_code
left join {{ source('gracethd', 't_local') }} lc2 on lc2.lc_code = ba.ba_lc_code
left join {{ source('gracethd', 't_site') }} st2 on st2.st_code = lc2.lc_st_code
left join {{ source('gracethd', 't_noeud') }} nd_ti on nd_ti.nd_code = st2.st_nd_code
where r.classe = 't_position'

-- ============================================================
-- 4. CLASSES AVEC HERITAGE VIA t_cableline
-- ============================================================

-- t_cable : cl_cb_code → t_cableline
union all
select r.*, cl.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_cableline') }} cl on cl.cl_cb_code = r.id_entite
where r.classe = 't_cable'

-- t_fibre : fo_cb_code → t_cable → cl_cb_code → t_cableline
union all
select r.*, cl.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_fibre') }} fo on fo.fo_code = r.id_entite
left join {{ source('gracethd', 't_cable') }} cb on cb.cb_code = fo.fo_cb_code
left join {{ source('gracethd', 't_cableline') }} cl on cl.cl_cb_code = cb.cb_code
where r.classe = 't_fibre'

-- ============================================================
-- 5. CLASSES SANS GEOMETRIE (fallback NULL)
-- ============================================================

-- Classes sans géométrie : t_cab_chem, t_love, t_organisme, t_reference
union all
select r.*, null::geometry as geom
from {{ ref('rapport_controles') }} r
where r.classe in (
  't_cab_chem',
  't_love',
  't_organisme',
  't_reference'
)

-- ============================================================
-- 6. FALLBACK FINAL : classes non explicitement mappées
-- ============================================================

union all
select r.*, null::geometry as geom
from {{ ref('rapport_controles') }} r
where r.classe not in (
  -- Direct geometry
  't_adresse', 't_cableline', 't_cheminement', 't_noeud', 't_pointaccueil',
  't_point_leve', 't_tranchee', 't_znro', 't_zsro', 't_zdep',
  -- Via t_noeud
  't_baie', 't_cassette', 't_ebp', 't_local', 't_position', 't_ptech', 't_site', 't_tiroir',
  -- Via t_cableline
  't_cable', 't_fibre',
  -- No geometry (explicit)
  't_cab_chem', 't_love', 't_organisme', 't_reference'
)

)

-- Clé primaire integer unique pour QGIS.
-- On régénère l'id : les jointures de résolution géométrique peuvent
-- multiplier les lignes (codes non uniques sur données non contrôlées),
-- donc l'id hérité de rapport_controles ne serait pas fiable comme PK.
select
  row_number() over ()::int4 as id,
  id_test,
  type_controle,
  description,
  classe,
  attribut,
  id_entite,
  detail_erreur,
  geom
from rapport_geo
