# Changelog

Toutes les évolutions notables de ce package sont documentées ici.

Format : [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/)

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
