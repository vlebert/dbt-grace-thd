# Changelog

Toutes les évolutions notables de ce package sont documentées ici.

Format : [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/)

---

## [1.6.0] - 2026-07-27

### Added

- **Criticité des contrôles** : nouvelle colonne `criticite` sur `rapport_controles`, ses variantes géolocalisées (`_geo`, `_geo_as_line`, `_geo_as_point`) et `synthese_erreurs_par_controle`, indexée (btree) sur chacune pour le filtrage et la catégorisation dans QGIS. Valeur `mineure` par défaut, surchargeable par liste d'`id_test` via la nouvelle variable `grace_criticite` — les libellés `majeure` et `bloquante` sont conventionnels, tout libellé libre est accepté. Une entrée peut être un id exact ou un **motif de famille** (`ctrl_uc_*`, `ctrl_fk_*`, `topo_*`, …), traduit en `LIKE` sur `id_test` avec échappement des caractères spéciaux ; les ids exacts sont évalués avant les motifs, ce qui permet les exceptions nominatives (`mineure: [ctrl_uc_0009]` face à `majeure: [ctrl_uc_*]`). **Aucun libellé n'a d'effet sur le run** : conformément au principe d'intégration non bloquante, `bloquante` sert à la restitution et n'interrompt rien.
- **Macro `get_criticite_expr`** (`macros/controls/get_criticite_expr.sql`) : seul point d'attribution de la criticité, appelé par `rapport_controles`. La criticité n'est donc portée ni par les modèles de contrôle ni par les seeds `param_ctrl_*` — même rationale que la géométrie, résolue en aval. La macro arrête la compilation avec un message explicite si `grace_criticite` est mal formée ou si un `id_test` est affecté à deux criticités différentes.
- **Nouvelles variables `grace_criticite_defaut`** (défaut `mineure`) **et `grace_criticite`** (défaut `{}`). Elles sont lues **sans valeur de repli** : le `dbt_project.yml` du package est leur source de vérité unique, et les supprimer casse la compilation. Un projet consommateur qui redéfinit `rapport_controles` dans son propre `models/` doit déclarer `grace_criticite_defaut` de son côté.

### Changed

- **Schéma des rapports élargi** : les cinq modèles de rapport portent une colonne supplémentaire. Les couches QGIS et les vues construites dessus la voient apparaître sans autre effet, mais un projet consommateur qui **surcharge** `rapport_controles` ou `rapport_controles_geo` dans son propre `models/` doit y ajouter `criticite`, faute de quoi les modèles aval du package (`_as_line`, `_as_point`, `synthese_erreurs_par_controle`) échouent à la sélectionner.

---

## [1.5.0] - 2026-07-22

### Added

- **Environnement de démonstration Docker** : pile complète PostGIS + dbt prête à l'emploi (`docker-compose.yml`, `docker/Dockerfile`, `docker/entrypoint.sh`, `docker/profiles.yml`, `.dockerignore`). L'image Python est construite avec `uv` pour des dépendances reproductibles.
- **Jeu de données d'exemple** : répertoire `input_data/` (shapefiles + CSV couvrant les principales classes GRACE THD) et sa documentation `input_data/README.md`, permettant de faire tourner le package sans données réelles.
- **Génération du schéma source** : script `scripts/generate_source_schema.py` et DDL généré `scripts/gracethd_source_schema.sql`, avec SRID imposé sur les colonnes géométriques.
- **Macros de cast non bloquant `safe_int` / `safe_numeric`** (`macros/safe_cast.sql`) : conversion numérique depuis des sources chargées en `text` brut, renvoyant `NULL` plutôt que d'échouer. Appliquées à `metier_0005` et `metier_0006`.
- **Macro `safe_geom` et variable `grace_srid`** (défaut `2154`, RGF93 / Lambert-93) : typage géométrique non bloquant (`MultiPoint` / `MultiLineString` / `MultiPolygon`), appliqué aux 10 modèles `base` spatiaux et à `elem_cb`. `grace_srid` est la source de vérité unique, partagée avec `generate_source_schema.py`.
- **Couche métadonnées** : nouveau modèle `meta_execution` (`date_donnees`, `date_execution`, `container_level`, `srid`), groupe de modèles `transformations/metadata` et tag `grace_meta`. La variable `grace_date_donnees` est une saisie manuelle validée au format `YYYY-MM-DD` : un format invalide arrête le run avec un message explicite.
- **Nouveau modèle `rapport_controles_geo_as_point`** : variante ponctuelle du rapport géolocalisé (pendant de `rapport_controles_geo_as_line`), pour une couche QGIS unique de type POINT quelle que soit la classe en erreur.
- **Nouveau modèle `ropt_json_route`** : construction du JSON au niveau route, extraite de `ropt_json`, avec index sur `lc_code` et `ropt_id`.
- **Nouveau contrôle `topo_0013`** (`t_cableline` / `geom`) : validité OGC de la géométrie via `ST_IsValidDetail`, le motif et la localisation du défaut étant restitués dans `detail_erreur`. Détecte notamment les tronçons dégénérés (extrémités confondues), qui empêchent `ST_LineMerge` de produire une multiligne — GEOS renvoie alors une `GEOMETRYCOLLECTION` hétérogène.
- **Licence, logos et refonte du README** : ajout du fichier `LICENSE`, des `assets/` (logos) et réécriture de la présentation du projet.

### Changed

- **⚠️ `grace_container_level` : défaut `C3` → `C4`** (`dbt_project.yml` et macros `get_topo_config` / `get_metier_config` / `get_rc_config`). Les projets consommateurs qui ne surchargent pas cette variable verront le périmètre des contrôles changer.
- **`ropt_json` et `pdb_json` matérialisés en vues** (au lieu de tables) : l'agrégation se fait à la volée au-dessus des modèles amont indexés, ce qui rend le predicate pushdown possible sur les recherches unitaires (point de branchement, local technique).
- **`pdb_json`** : `id` dérivé de `MIN(bp_id)` plutôt que d'un `row_number()`, compatible avec la matérialisation en vue.
- **`ropt_light` désactivé** (`+enabled: false`) : aucun modèle en aval ne le référence.
- **`elem_cs_ti`** : dédoublonnage des positions sur `(ps_cs_code, ps_ti_code)` dans une CTE **avant** les jointures — `t_position` contient une ligne par fibre, ce qui provoquait un fan-out coûteux avec la géométrie en charge utile.
- **`row_number() OVER ()` sans `ORDER BY`** dans les modèles élémentaires (`elem_bp`, `elem_cs`, …) : l'ordre n'avait pas de portée fonctionnelle et forçait un tri global sur des lignes portant la géométrie.
- **`rc_0401`** (`t_cheminement` / `cm_compo`) : le cas Orange est restreint aux conduites (`cm_typ_imp = '7'`) ; `cm_typ_imp` est exposé dans le détail d'erreur.
- **`metier_0008`** (`t_zsro` / `zs_r3_lc_codeext`) désactivé dans `param_ctrl_metier`.
- **Script d'import** : `scripts/import_grace_pg.sh` remplacé par `scripts/import_grace_pg.py`, avec prise en charge des GeoPackage (`.gpkg`) et auto-détection du format en entrée (GeoPackage, ou répertoire de shapefiles / CSV).

### Fixed

- **Macro `safe_geom`** : le typage géométrique échouait en erreur SQL bloquante (`Geometry type (GeometryCollection) does not match column type (MultiLineString)`) lorsque l'expression en entrée produisait une `GEOMETRYCOLLECTION` — cas rencontré sur `elem_cb` via `ST_LineMerge` d'une cableline contenant un tronçon de longueur nulle. `ST_Multi` laisse une collection inchangée, et le contrôle de typmod PostGIS lève une erreur *dure* que `pg_input_is_valid` n'intercepte pas. La macro s'appuie désormais sur `ST_CollectionExtract` (ne conserve que les composants de la dimension visée) avec contrôle explicite du SRID, et renvoie `NULL` si le résultat est vide.

### Performance

- **Index GiST sur les 10 tables sources géométriques** (`t_adresse`, `t_cableline`, `t_cheminement`, `t_noeud`, `t_point_leve`, `t_pointaccueil`, `t_tranchee`, `t_zdep`, `t_znro`, `t_zsro`) via `create_source_indexes`, au bénéfice des contrôles topologiques.
- **`t_local`** : ajout de 10 index btree (`lc_st_code`, `lc_bp_codf`, `lc_bp_codp`, `lc_typelog`, `lc_prop`, `lc_gest`, `lc_proptyp`, `lc_statut`, `lc_avct`, `lc_etiquet`).

### Documentation

- Documentation de la couche métadonnées, du typage géométrique non bloquant, de la matérialisation en tables et des index (`ARCHITECTURE_TRANSFORMATIONS.md`, `UTILISATION_PACKAGE.md`), de la variante ponctuelle du rapport (`ARCHITECTURE_CONTROLES.md`) et du jeu de données d'exemple.

---

## [1.4.0] - 2026-07-20

### Added

- **Nouveau modèle `rapport_controles_geo_as_line`** : variante de `rapport_controles_geo` ramenant toutes les géométries à un type LIGNE homogène (`MULTILINESTRING`), pour disposer d'une couche QGIS unique restituant les erreurs quelle que soit la classe. Stratégie de conversion : polygones → contour (`ST_Boundary`), lignes conservées, points → petit segment centré sur le point.
- **Variable `grace_rapport_point_line_offset`** (défaut `1.0`) : demi-longueur (en unités du CRS, mètres pour GRACE THD) du segment généré à partir d'un point dans `rapport_controles_geo_as_line`.
- **Clés primaires QGIS sur les modèles de rapport** : ajout d'une colonne `id` (`int4`, `row_number()`) exposée en `PRIMARY KEY` via `post_hook` sur `rapport_controles`, `rapport_controles_geo` et `synthese_erreurs_par_controle`, pour permettre l'affichage des tables dans QGIS.
- **Index sur les modèles de rapport** : index btree sur `type_controle` (`rapport_controles`, `rapport_controles_geo`) et index gist sur `geom` (`rapport_controles_geo`).
- **Tag `grace_transfo`** sur le groupe de modèles `transformations`, permettant de sélectionner l'ensemble des transformations d'un seul tenant.

### Changed

- **`rapport_controles_geo_as_line`** : les points sont désormais convertis en petit segment centré (via `ST_Translate`) plutôt qu'en ligne de longueur nulle, qui ne s'affichait pas dans QGIS. La longueur est paramétrable via `grace_rapport_point_line_offset`.
- **`rapport_controles_geo`** : l'`id` de clé primaire est régénéré après les jointures de résolution géométrique (celles-ci pouvant multiplier les lignes sur données non contrôlées), et non hérité de `rapport_controles`.

---

## [1.3.0] - 2026-07-18

### Added

- **Thématique `ropt` — modèle `ropt_json`** : nouveau modèle de transformation agrégeant les attributs de route optique en sortie JSON (`ropt_json.sql` / `.yml`).
- **Thématique `capacite` — modèle `cap_zpbo`** : calcul des zones de desserte PBO avec les locaux raccordés. `cap_pbo` s'appuie désormais sur `cap_zpbo` pour le comptage des locaux (au lieu d'un calcul direct).
- **Thématique `capacite` — modèle `cap_syno_json`** : génération d'un graphe synoptique (source/target par boîtier) pour l'analyse de capacité.
- **Champs étiquette** (`bp_etiquet`, `lc_etiquet`, `pt_etiquet`, `ti_etiquet`, `cb_etiquet`) exposés dans les modèles thématiques `pdb_json`, `ropt_json` et `ropt_section`.
- **Prise en charge du type BPI** dans `elem_bp` et le modèle de capacité `cap_syno_json` (filtrage, documentation et génération de graphe).

### Changed

- **`ropt_json`** : requête optimisée en agrégation conditionnelle single-pass (suppression des CTE intermédiaires).
- **`topo_0012`** (`t_cable` / incohérence de longueur) : requête de détection optimisée.

### Fixed

- **Contrôles de remplissage conditionnel robustes aux chaînes vides** : les 38 contrôles `rc_*` ainsi que `metier_0004` testaient uniquement `IS NULL`, ce qui manquait les valeurs `''` (chaîne vide) présentes lorsque les sources sont chargées en `text` brut plutôt que typées. Le test devient `IS NULL OR trim(<col>::text) = ''`, garantissant une détection fiable quel que soit le mode d'import.
- **`cap_syno_json`** : résolution des extrémités de boîtier sur tous les types (PBO/BPE/PM) et non plus seulement PBO ; ajout d'un `LEFT JOIN` via `cap_pbo` pour préserver les compteurs `NULL` des boîtiers non-PBO et éviter que `source`/`target` deviennent `NULL` à tort.

### Performance

- **`ropt_section`** : consolidation des index en un index composite unique et ajout d'un index sur `bp_code`.

---

## [1.2.0] - 2026-06-22

### Added

- **Clé primaire sur les tables de référence (`seeds/listes/`)** : ajout d'une colonne `id` (`int4`) à séquence unique dans chacun des 44 seeds, typée via `+column_types` et exposée comme `PRIMARY KEY` via un `post-hook` idempotent (`DROP CONSTRAINT IF EXISTS` + `ADD CONSTRAINT … PRIMARY KEY (id)`). Permet l'affichage des listes dans QGIS, qui requiert une clé primaire reconnue.
- **Modèle thématique PDB** : nouveau modèle de transformation `pdb` avec agrégation JSON.
- **Modèle capacité SRO** : ajout des métriques liées aux câbles de distribution.

### Documentation

- Clarification des exigences de compatibilité QGIS concernant les clés primaires dans `ARCHITECTURE_TRANSFORMATIONS.md`.

---

## [1.1.7] - 2026-06-16

### Performance

- **Matérialisation en tables** des modèles élémentaires `elem_cb`, `elem_bp`, `elem_cs` et `elem_ps` pour accélérer les modèles en aval qui les référencent fréquemment.

### Fixed

- **Compatibilité QGIS** : cast `::int4` sur tous les `row_number()` générés comme clé primaire `id` dans les modèles de transformation (`base/`, `elementaires/`, `thematiques/capacite/`). QGIS requiert `integer` (`int4`) et non `bigint` (`int8`).

### Added

- **Clé primaire sur `ropt_light`** : ajout de `ropt_id::int4 AS id` et du `post_hook` `ALTER TABLE ... ADD PRIMARY KEY (id)` pour exposer la table dans QGIS avec une clé primaire reconnue.

### Documentation

- Ajout de la documentation des vues thématiques dans `ARCHITECTURE_TRANSFORMATIONS.md` et `README.md`.

---

## [1.1.6] - 2026-06-15

### Performance

- Optimisation de la requête `metier_0013` pour améliorer les performances.

---

## [1.1.5] - 2026-06-12

### Added

- **Création automatique des index sources** : nouvelle macro `create_source_indexes` (`macros/controls/create_source_indexes.sql`) déclenchée en `pre-hook` sur tous les modèles de contrôle (`models/controls/`). Crée les index sur les tables sources GRACE THD avant l'exécution des contrôles.
  - Schéma source résolu dynamiquement via le graph dbt (source `gracethd`).
  - **Non-bloquant** : table et colonnes vérifiées dans `information_schema` avant chaque `CREATE` ; les tables/colonnes absentes sont ignorées silencieusement.
  - **Idempotent** : index déjà présents filtrés via `pg_indexes` + `CREATE INDEX IF NOT EXISTS` ; les appels répétés (1 par modèle de contrôle) sont quasi gratuits.
- **Script `scripts/generate_index_macro.py`** : génère la macro depuis `scripts/gracethd_indexes.sql` (qui reste la source de vérité, utilisable directement via `psql`).

---

## [1.1.4] - 2026-06-04

### Fixed

- `cap_pbo` : correction d'un doublon sur la clé primaire `id` causé par plusieurs ZSRO partageant le même `zs_lc_code`. La jointure sur `t_zsro` utilise désormais une CTE `zsro_dedup` (`DISTINCT ON (zs_lc_code)`) pour garantir l'unicité.

### Added

- **Contrôle métier `metier_0020`** (`t_zsro` / `zs_lc_code`) : détecte les zones SRO qui référencent le même local technique (`zs_lc_code` dupliqué dans `t_zsro`). Le détail d'erreur expose le `lc_code`, `lc_codeext`, `lc_typelog` du local concerné ainsi que la liste de toutes les ZSRO en collision.

---

## [1.1.3] - 2026-06-04

### Changed

- Amélioration des descriptions de 14 contrôles spécifiques métier et topologie (`metier_0002` à `metier_0014`, `topo_0005` à `topo_0011`)

---

## [1.1.2] - 2026-05-26

### Changed

- **Centralisation de la configuration dbt** : `schema`, `materialized` et tags de famille déplacés de chaque fichier SQL vers `dbt_project.yml`. Les blocs `{{ config() }}` inline ne contiennent plus que les spécificités du modèle (`post_hook`, `pre_hook`, `indexes`).
  - `elementaires/` : blocs `{{ config() }}` supprimés entièrement (18 fichiers)
  - `base/` : `materialized`, `schema`, `tags` supprimés des config inline (24 fichiers)
  - `thematiques/capacite/` et `thematiques/ropt/` : idem (7 fichiers)
  - `controls/generique/` : ligne config supprimée entièrement (6 fichiers)
  - `controls/` rapports : `materialized` supprimé, `tags` conservés (3 fichiers)
- `dbt_project.yml` : ajout de `+materialized: table` au niveau `controls:` et `thematiques:` ; ajout de `+tags: ["grace_thematiques"]` au niveau `thematiques:` ; sous-répertoires `capacite:` et `ropt:` avec leurs tags additifs (`grace_capacite`, `grace_ropt`)

---

## [1.1.1] - 2026-05-26

### Added

- **Thématique `capacite`** : 4 nouveaux modèles matérialisés en table (`grace_capacite`) :
  - `cap_pbo` — attributs et compteurs de capacité par PBO (fibres distribuées, fibres raccordées, locaux desservis, zone SRO)
  - `cap_cb_pbo` — table intermédiaire câble DI × destination PBO avec compteurs de fibres et zone SRO
  - `cap_cb` — attributs et compteurs de capacité par câble DI (agrégation depuis `cap_cb_pbo`)
  - `cap_sro` — locaux SRO enrichis du nombre de fibres transport (types TR/CT)
- Clé primaire entière sur les 4 modèles (`post_hook ALTER TABLE ADD PRIMARY KEY`) pour compatibilité QGIS
- Index btree sur les colonnes de jointure fréquentes (`bp_code`, `cb_code`, `lc_code`)
- `ANALYZE` en `pre_hook` sur `ropt_section`, `ropt` et `t_fibre` pour les modèles les plus coûteux

### Fixed

- **`elem_cb`** : bug de précédence SQL dans la branche UNION ALL des câbles sans `t_cableline` — la condition `OR cl.cl_code <> ''` incluait à tort des câbles déjà présents dans la première branche (avec cableline), provoquant des doublons dans tous les modèles consommateurs. Corrigé en restreignant à `WHERE cl.cl_code IS NULL AND nd1.geom IS NOT NULL AND nd2.geom IS NOT NULL`.

### Changed

- `cap_pbo` : requête `ropt_section` passée en lecture unique grâce à `FIRST_VALUE()` (remplacement de la CTE `ropt_start` + auto-jointure) et `LAG()` (remplacement de la CTE `loc_par_pbo` + auto-jointure)
- `cap_cb_pbo` : CTE `destination` réécrite en `GROUP BY` unique avec `ARRAY_AGG FILTER` à la place d'une auto-jointure sur `(ropt_id, ropt_ordr = 0)`

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
