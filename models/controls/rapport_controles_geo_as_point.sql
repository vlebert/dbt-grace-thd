{{
  config(
    tags=['grace_rapport'],
    post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
    indexes = [
      {'columns': ['geom'], 'type': 'gist'},
      {'columns': ['criticite'], 'type': 'btree'}
    ]
  )
}}

{#
  Variante de rapport_controles_geo où toutes les géométries sont ramenées
  à un type POINT homogène (MULTIPOINT). Objectif : disposer d'une couche
  QGIS unique restituant les erreurs, quelle que soit la classe (pendant
  ponctuel de rapport_controles_geo_as_line).

  Stratégie de conversion :
    - Polygone / multipolygone : point garanti à l'intérieur (ST_PointOnSurface,
      et non ST_Centroid qui peut tomber hors d'un polygone concave ou troué)
    - Ligne / multiligne       : point au milieu de la ligne (ST_LineInterpolatePoint
      à 0.5). ST_LineMerge recolle les tronçons contigus d'une multiligne ;
      si elle reste éclatée, le premier composant est utilisé.
    - Point / multipoint       : conservé tel quel

  Transformation 1:1 de rapport_controles_geo : l'`id` reste unique et
  peut être réutilisé comme clé primaire.
#}

select
  id,
  id_test,
  type_controle,
  description,
  classe,
  attribut,
  id_entite,
  detail_erreur,
  criticite,
  case
    when geom is null or st_isempty(geom) then null
    when geometrytype(geom) in ('POINT', 'MULTIPOINT')
      then st_multi(geom)
    when geometrytype(geom) in ('POLYGON', 'MULTIPOLYGON')
      then st_multi(st_pointonsurface(geom))
    when geometrytype(geom) in ('LINESTRING', 'MULTILINESTRING')
      then st_multi(
             st_lineinterpolatepoint(
               st_geometryn(st_linemerge(geom), 1),
               0.5
             )
           )
    else st_multi(st_pointonsurface(geom))
  end as geom
from {{ ref('rapport_controles_geo') }}
