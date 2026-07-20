{{
  config(
    tags=['grace_rapport'],
    post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
    indexes = [
      {'columns': ['geom'], 'type': 'gist'}
    ]
  )
}}

{#
  Variante de rapport_controles_geo où toutes les géométries sont ramenées
  à un type LIGNE homogène (MULTILINESTRING). Objectif : disposer d'une
  couche QGIS unique restituant les erreurs, quelle que soit la classe.

  Stratégie de conversion :
    - Polygone / multipolygone : contour (ST_Boundary)
    - Ligne / multiligne       : conservée telle quelle
    - Point / multipoint       : petit segment centré sur le point

  Une ligne de longueur nulle (départ = arrivée) ne s'affiche pas dans QGIS,
  d'où le petit segment. Sa longueur dépend du système de coordonnées des
  données (projeté en mètres pour GRACE THD) et est paramétrable via la
  variable `grace_rapport_point_line_offset` (demi-longueur, en unités du
  CRS ; défaut : 1).

  Transformation 1:1 de rapport_controles_geo : l'`id` reste unique et
  peut être réutilisé comme clé primaire.
#}

{%- set pt_offset = var('grace_rapport_point_line_offset', 1.0) -%}

select
  id,
  id_test,
  type_controle,
  description,
  classe,
  attribut,
  id_entite,
  detail_erreur,
  case
    when geom is null then null
    when geometrytype(geom) in ('POLYGON', 'MULTIPOLYGON')
      then st_multi(st_boundary(geom))
    when geometrytype(geom) in ('POINT', 'MULTIPOINT')
      then st_multi(
             st_makeline(
               st_translate(st_centroid(geom), -{{ pt_offset }}, 0),
               st_translate(st_centroid(geom),  {{ pt_offset }}, 0)
             )
           )
    else st_multi(geom)
  end as geom
from {{ ref('rapport_controles_geo') }}
