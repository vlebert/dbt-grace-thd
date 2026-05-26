# Changelog

Toutes les évolutions notables de ce package sont documentées ici.

Format : [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/)

---

## [1.1.0] - 2026-05-26

### Changed

- **`rapport_controles`** : résolution des dépendances par tag dbt (`grace_control`) plutôt que par liste explicite dans `dbt_project.yml`. Les nouveaux contrôles n'ont plus à être déclarés manuellement — le tag suffit.
- Les modèles de rapport (`rapport_controles`, `rapport_controles_geo`, `synthese_erreurs_par_controle`) ne portent plus le tag `grace_control` mais uniquement `grace_rapport`, ce qui permet de séquencer l'exécution proprement : `dbt run --select tag:grace_control && dbt run --select tag:grace_rapport`.

### Removed

- Suppression de la variable `grace_ctrl_models` et `grace_ctrl_models_ext` : l'extension se fait désormais uniquement par tag `grace_control`.
- Suppression de la fonctionnalité de surcharge des seeds de paramétrage depuis un projet consommateur (conflits de schéma de destination).

---

## [1.0.0] - 2026-05-26

### Added

- Contrôles génériques paramétrés par seeds : présence des tables, remplissage obligatoire, unicité, clés étrangères, listes de valeurs, vérification de types
- Contrôles spécifiques : remplissage conditionnel (41 règles), topologie (12 règles), règles métier (19 règles)
- Rapports consolidés `rapport_controles` (7 colonnes) et `rapport_controles_geo` (avec géolocalisation)
- Transformations base (23 tables avec typage non-bloquant) et élémentaires (18 vues avec projection géométrique)
- Gestion du niveau de conteneur C1–C4 via la variable `grace_container_level`
- Script d'import des données source (`import_grace_pg.py`)
- 44 listes de valeurs de référence GRACE THD
