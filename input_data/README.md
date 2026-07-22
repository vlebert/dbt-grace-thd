# `input_data/` — jeu de données d'entrée

Ce dossier contient les données réseau à charger dans le schéma `gracethd_source`
(sources dbt du package). Par défaut, il embarque un **échantillon public** ; il suffit
d'en **remplacer le contenu** par vos propres données pour faire tourner le pipeline
sur votre réseau, sans modifier aucune commande.

## Formats acceptés (détection automatique)

Le script `scripts/import_grace_pg.py` détecte automatiquement la source présente dans
ce dossier :

- **GeoPackage** : un unique fichier `*.gpkg` regroupant toutes les couches `t_*`.
- **Shapefiles + CSV** : les couches géométriques en `t_*.shp` (+ `.dbf/.prj/.shx`) et
  les tables attributaires en `t_*.csv`.

Si un `.gpkg` est présent, il est prioritaire ; sinon le mode shapefiles/CSV est utilisé.

## Comment utiliser vos propres données

1. Videz ce dossier (ou remplacez les fichiers `t_*`).
2. Déposez soit votre `reseau.gpkg`, soit vos `t_*.shp` + `t_*.csv`.
3. Relancez l'import : `python scripts/import_grace_pg.py input_data <cible_dbt>`
   (ou `docker compose up --build` pour le parcours Docker).

Les noms de tables attendus suivent le modèle GRACE THD (`t_adresse`, `t_cable`,
`t_noeud`, …). Les colonnes absentes ne bloquent pas l'import : elles restent NULL et
sont signalées par les contrôles de remplissage (intégration non bloquante).

## Échantillon fourni par défaut

- **Source** : jeu de données public de recommandations de modélisation GRACE THD (ANCT).
  <https://anct.gouv.fr/ressources/publications/recommandations-modelisation-des-reseaux-gracethd>
- **Version** : GRACE THD v3.0 (le package cible v3.0.1 ; quelques colonnes diffèrent, ce
  qui illustre justement les contrôles non bloquants).
- **Système de coordonnées** : RGF93 / Lambert-93 (EPSG:2154).

> Cet échantillon est volontairement conservé « tel quel » : il comporte des imperfections
> de qualité, idéales pour illustrer les contrôles GRACE THD.
