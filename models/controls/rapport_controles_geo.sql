{{ config(materialized='table', tags=['rapport']) }}

{#
  Rapport consolidé géolocalisé.

  Enrichit `rapport_controles` d'une colonne `geom` en résolvant par
  (classe, id_entite). Chaque classe connue a sa stratégie de résolution
  explicite (UNION ALL) :

    - Classes spatiales directes         → geom lue sur la table source
    - Héritage noeud partagé (ba_code = nd_code, etc.)
                                         → jointure t_noeud via id_entite
    - Héritage noeud via FK explicite (t_ptech, t_site)
                                         → jointure via xx_nd_code
    - Héritage cableline (t_cable, t_fibre)
                                         → jointure t_cableline via FK inversée
    - Classes non mappées                → geom NULL (fallback)

  Pour couvrir une nouvelle classe : ajouter une branche UNION ALL. Pour gérer
  un cas multi-niveau, empiler des JOIN dans la branche correspondante.

  NOTE : les conventions d'héritage (ba_code = nd_code, etc.) sont à valider
  contre le schéma réel du projet.
#}

-- Placeholder : schéma stable même si rapport_controles est vide
select
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
-- Classes spatiales directes
-- ============================================================

union all
select r.*, t.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_adresse') }} t on t.ad_code = r.id_entite
where r.classe = 't_adresse'

union all
select r.*, t.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_cableline') }} t on t.cl_code = r.id_entite
where r.classe = 't_cableline'

union all
select r.*, t.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_cheminement') }} t on t.cm_code = r.id_entite
where r.classe = 't_cheminement'

union all
select r.*, t.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_noeud') }} t on t.nd_code = r.id_entite
where r.classe = 't_noeud'

union all
select r.*, t.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_tranchee') }} t on t.tr_code = r.id_entite
where r.classe = 't_tranchee'

union all
select r.*, t.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_znro') }} t on t.zn_code = r.id_entite
where r.classe = 't_znro'

-- ============================================================
-- Héritage noeud partagé : xx_code EST le nd_code
-- (t_baie, t_cassette, t_ebp, t_local, t_position, t_tiroir)
-- ============================================================

union all
select r.*, n.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_noeud') }} n on n.nd_code = r.id_entite
where r.classe in (
  't_baie',
  't_cassette',
  't_ebp',
  't_local',
  't_position',
  't_tiroir'
)

-- ============================================================
-- Héritage noeud via FK explicite (xx_nd_code)
-- (t_ptech, t_site)
-- ============================================================

union all
select r.*, n.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_ptech') }} t on t.pt_code = r.id_entite
left join {{ source('gracethd', 't_noeud') }} n on n.nd_code = t.pt_nd_code
where r.classe = 't_ptech'

union all
select r.*, n.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_site') }} t on t.st_code = r.id_entite
left join {{ source('gracethd', 't_noeud') }} n on n.nd_code = t.st_nd_code
where r.classe = 't_site'

-- ============================================================
-- Héritage cableline via FK inversée (cableline.cl_cb_code = cable.cb_code)
-- (t_cable)
-- Pour t_fibre : via fo_cb_code → cable → cableline (2 niveaux), à ajouter
-- lorsque des contrôles fibre seront en place.
-- ============================================================

union all
select r.*, cl.geom
from {{ ref('rapport_controles') }} r
left join {{ source('gracethd', 't_cableline') }} cl on cl.cl_cb_code = r.id_entite
where r.classe = 't_cable'

-- ============================================================
-- Fallback : classes non mappées → geom NULL
-- ============================================================

union all
select r.*, null::geometry as geom
from {{ ref('rapport_controles') }} r
where r.classe not in (
  't_adresse', 't_cableline', 't_cheminement', 't_noeud', 't_tranchee', 't_znro',
  't_baie', 't_cassette', 't_ebp', 't_local', 't_position', 't_tiroir',
  't_ptech', 't_site',
  't_cable'
)
