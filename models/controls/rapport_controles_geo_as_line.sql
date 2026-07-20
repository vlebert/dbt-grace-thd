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
    - Point / multipoint       : ligne de longueur nulle (départ = arrivée)

  NB : la ligne dégénérée générée pour un point risque de ne pas s'afficher
  dans QGIS (longueur 0). À valider sur les données réelles.

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
  case
    when geom is null then null
    when geometrytype(geom) in ('POLYGON', 'MULTIPOLYGON')
      then st_multi(st_boundary(geom))
    when geometrytype(geom) in ('POINT', 'MULTIPOINT')
      then st_multi(st_makeline(st_centroid(geom), st_centroid(geom)))
    else st_multi(geom)
  end as geom
from {{ ref('rapport_controles_geo') }}
