# Architecture des transformations - Package DBT pour GRACE THD

**Documentation technique des transformations de données**

> **Pour une présentation générale du projet** : [Retour au README](README.md)

---

## Vue d'ensemble

Les transformations GRACE THD sont organisées en **trois couches** avec une chaîne de dépendances claire :

1. **Base** (`base/`) — 23 tables avec typage non-bloquant, clés primaires et index
2. **Élémentaires** (`elementaires/`) — 18 vues (par défaut) construites sur les tables base, avec possibilité d'override en `table`
3. **Thématiques** (`thematiques/`) — Transformations avancées par thème métier (à venir)

S'y ajoute une couche transverse **Métadonnées** (`metadata/`), sans dépendance aux données.

---

## Couche Base

**Dossier** : `models/transformations/base/`

**Rôle** : Répliquer les tables sources du schéma `gracethd_source` dans le schéma `transformations` avec :
- **Typage non-bloquant** via `pg_input_is_valid(NULLIF(champ::text, ''), 'type_postgres')`
- **Nettoyage des valeurs vides** : les chaînes vides (`''`) sont converties en `NULL` avant validation
- **Clé primaire technique** : colonne `id` générée via `row_number() OVER (ORDER BY pk_naturelle)::int4`. Le cast `::int4` est **obligatoire** : par défaut `row_number()` renvoie un `bigint` (`int8`), or **QGIS exige une clé primaire de type `int4`** pour gérer une couche en édition.
- **Index** : index btree sur toutes les colonnes pertinentes + index gist sur `geom` pour les tables spatiales
- **Typage géométrique non-bloquant** de la colonne `geom` (10 tables spatiales) via le macro `safe_geom` : normalisation `ST_Multi` + contrainte de type/SRID, `NULL` si non conforme

**Pattern de typage non-bloquant (scalaires)** :
```sql
CASE WHEN pg_input_is_valid(NULLIF(champ::text, ''), 'type_postgres')
     THEN champ::TYPE ELSE NULL END AS alias
```

**Pattern de typage géométrique** (macro `safe_geom`) :
```sql
CAST(
  CASE WHEN pg_input_is_valid(NULLIF(ST_AsEWKT(ST_Multi(geom)), ''), 'geometry(<Type>,<srid>)')
       THEN ST_Multi(geom) ELSE NULL END
  AS geometry(<Type>, <srid>)
)
```
Le SRID provient de la variable projet **`grace_srid`** (défaut `2154`, RGF93 / Lambert-93) —
source de vérité unique partagée avec le DDL des sources (`scripts/generate_source_schema.py`).
Le **CAST externe** porte le typmod : sans lui, un `CASE` seul renverrait une géométrie
générique (`GEOMETRY` / SRID `0`), le typmod étant perdu à la sortie du `CASE`.

**Configuration standard** :
```sql
{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['grace_base'],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['colonne_1'], 'type': 'btree'},
            {'columns': ['colonne_2'], 'type': 'btree'},
            {'columns': ['geom'], 'type': 'gist'},  -- pour les tables spatiales
        ]
    )
}}
```

**Tables spatiales et type géométrique** (10/23, SRID `grace_srid`) :
- `MULTIPOINT` : t_adresse, t_noeud, t_pointaccueil, t_point_leve
- `MULTILINESTRING` : t_cableline, t_cheminement, t_tranchee
- `MULTIPOLYGON` : t_zdep, t_znro, t_zsro

**Liste complète des 23 tables base** :
t_adresse, t_baie, t_cable, t_cableline, t_cassette, t_cheminement, t_fibre, t_local, t_noeud, t_organisme, t_ebp, t_ptech, t_point_leve, t_pointaccueil, t_position, t_reference, t_site, t_tiroir, t_tranchee, t_zdep, t_znro, t_zsro, t_zpbo

---

## Couche Élémentaire

**Dossier** : `models/transformations/elementaires/`

**Rôle** : Construire des jointures et transformations élémentaires **sur les tables base** (`ref('t_*')`) pour :
- Projeter une géométrie (`geom`) sur des tables qui n'en ont pas
- Fournir une base normalisée pour les transformations thématiques
- Permettre un override de matérialisation par les utilisateurs du package

### Conventions

| Élément | Règle |
|---|---|
| **Préfixe** | `elem_` |
| **Matérialisation** | `view` **par défaut**, override possible en `table` via `dbt_project.yml`. Exceptions matérialisées en `table` dans le modèle : `elem_cb`, `elem_bp`, `elem_cs`, `elem_ps` (voir ci-dessous) |
| **Tags** | `grace_elem` sur tous les modèles (+ `grace_transfo`, tag global commun à toutes les transformations) |
| **Schéma** | `transformations` |
| **Documentation** | 1 fichier `.yml` par modèle |
| **Géométrie** | `geom` en dernière colonne, **typée** (SRID `grace_srid`) : héritée automatiquement des tables `base` typées, sauf `elem_cb` (reconstruction → `safe_geom`) |
| **Clé primaire** | `id` héritée de la table base source |

> **Note QGIS** : La colonne `id` (type `int4`) est **sourcée depuis les tables base** via `{alias}.id`, offrant une clé primaire stable sans régénération. Le type `int4` est conservé tel quel depuis la base (cast appliqué à la source), car **QGIS exige une clé primaire `int4`** pour éditer une couche.

### Typologie

| Catégorie | Description | Exemples |
|---|---|---|
| **Projection directe** | Jointure 1:1 table → géométrie | elem_st_nd, elem_pt_nd, elem_cl_cb |
| **Chaînée** | Jointure multi-niveaux (2-4 tables) | elem_lc_st_nd, elem_bp_lc_st_nd, elem_ba_lc_st_nd |
| **Complexe** | Géométrie construite (UNION/COALESCE/MakeLine) | elem_cb, elem_bp |
| **Hiérarchique** | UNION ALL de plusieurs sources | elem_cs, elem_ps |
| **Filtrage** | Avec conditions métier spécifiques | elem_pto |

### Liste des 18 modèles

| Modèle | Description | Source Base |
|---|---|---|
| `elem_st_nd` | t_site → t_noeud | ref('t_site'), ref('t_noeud') |
| `elem_lc_st_nd` | t_local → t_site → t_noeud | ref('t_local'), ref('t_site'), ref('t_noeud') |
| `elem_bp_lc_st_nd` | t_ebp → t_local → t_site → t_noeud (INNER JOIN lc) | ref('t_ebp'), ref('t_local'), ref('t_site'), ref('t_noeud') |
| `elem_bp_pt_nd` | t_ebp → t_ptech → t_noeud | ref('t_ebp'), ref('t_ptech'), ref('t_noeud') |
| `elem_pt_nd` | t_ptech → t_noeud | ref('t_ptech'), ref('t_noeud') |
| `elem_cl_cb` | t_cable → t_cableline | ref('t_cable'), ref('t_cableline') |
| `elem_cb` | t_cable : UNION ALL (cableline OU MakeLine(nd1, nd2)) | ref('t_cable'), ref('t_noeud') |
| `elem_bp` | t_ebp (PBO/BPE) : COALESCE géométrie pt ou st | ref('t_ebp'), ref('t_ptech'), ref('t_site') |
| `elem_pto` | t_ebp (PTO) → t_adresse, filtre `bp_typelog = 'PTO'` | ref('t_ebp'), ref('t_adresse') |
| `elem_ba_lc_st_nd` | t_baie → t_local → t_site → t_noeud | ref('t_baie'), ref('t_local'), ref('t_site'), ref('t_noeud') |
| `elem_ti_ba_lc_st_nd` | t_tiroir → t_baie → t_local → t_site → t_noeud | ref('t_tiroir'), ref('t_baie'), ... |
| `elem_fo_cb_cl` | t_fibre → t_cable → t_cableline | ref('t_fibre'), ref('t_cable'), ref('t_cableline') |
| `elem_cs_bp` | t_cassette → ref(elem_bp) | ref('t_cassette'), ref('elem_bp') |
| `elem_cs_ti` | t_cassette → ref(elem_ti), WHERE cs_bp_code IS NULL | ref('t_cassette'), ref('elem_ti') |
| `elem_cs` | UNION ALL elem_cs_bp + elem_cs_ti | - |
| `elem_ps_cs` | t_position → ref(elem_cs) | ref('t_position'), ref('elem_cs') |
| `elem_ps_ti` | t_position → ref(elem_ti) | ref('t_position'), ref('elem_ti') |
| `elem_ps` | UNION ALL elem_ps_cs + elem_ps_ti | - |

### Pattern de jointure et géométrie

- **LEFT JOIN** : Utilisé par défaut pour les relations optionnelles
- **INNER JOIN** : Utilisé quand la relation est obligatoire (ex: `bp.bp_lc_code = lc.lc_code`)
- **COALESCE** : Pour gérer plusieurs sources de géométrie possibles (ex: elem_bp : pt OU st)
- **ST_MakeLine** : Pour construire une géométrie à partir de points (elem_cb : nd1 → nd2)
- **UNION ALL** : Pour combiner plusieurs sources (elem_cb, elem_cs, elem_ps)
- **Typage geom** : hérité **automatiquement** des tables `base` typées — une simple référence de colonne (`nd.geom`) ou un `COALESCE` de géométries de même type conservent le typmod. Seul `elem_cb`, qui **reconstruit** la géométrie (`ST_LineMerge` / `ST_MakeLine` → géométrie générique), réapplique explicitement `safe_geom('MultiLineString')` sur le SELECT final.

### Modèles matérialisés en `table` (performance)

`elem_cb`, `elem_bp`, `elem_cs` et `elem_ps` sont **matérialisés en `table`** (override dans le `config()` du modèle) plutôt qu'en vue, car ce sont des transformations plus lourdes qu'une simple jointure (`UNION ALL`, `COALESCE`/multi-jointures, construction de géométrie) dont la matérialisation accélère les usages SIG en aval.

Ces tables recréent, via la clé `indexes` du `config()`, **les index de leur table base source** :
- `elem_cb` ← index de `t_cable` (`cb_code`, `cb_nd1`, `cb_nd2`, `cb_prop`, `cb_gest`, `cb_proptyp`, `cb_statut`, `cb_avct`, `cb_typephy`, `cb_typelog`) + `gist` sur `geom`
- `elem_bp` ← index de `t_ebp` (`bp_code`, `bp_pt_code`, `bp_prop`, `bp_gest`, `bp_proptyp`, `bp_statut`, `bp_avct`, `bp_rf_code`) + `gist` sur `geom`
- `elem_cs` ← index de `t_cassette` (`cs_code`, `cs_bp_code`, `cs_rf_code`, `cs_type`) + `gist` sur `geom`
- `elem_ps` ← index de `t_position` (`ps_code`, `ps_numero`, `ps_1`, `ps_2`, `ps_cs_code`, `ps_ti_code`, `ps_type`, `ps_fonct`) + `gist` sur `geom`

> **PK régénérée** : sur ces quatre modèles, l'`id` hérité de la table base **n'est pas garanti unique** (recouvrement entre branches d'`UNION ALL` pour `elem_cb`/`elem_cs`/`elem_ps` ; fan-out des jointures sur codes non contraints pour `elem_bp`). L'`id` est donc **régénéré via `row_number() ... ::int4`** dans le SELECT final, garantissant une `PRIMARY KEY` (ajoutée en `post_hook`) toujours unique et non bloquante. Le cast `::int4` reste obligatoire (`row_number()` renvoie un `int8` par défaut, incompatible avec l'édition QGIS). C'est la seule exception à la note « id sourcé depuis base » ci-dessus.

---

## Couche Thématique

**Dossier** : `models/transformations/thematiques/`

Réservé pour les transformations avancées par thème métier (ex: dimensionnement, topologie, rapports).
À développer ultérieurement.

---

## Couche Métadonnées

**Dossier** : `models/transformations/metadata/`

### `meta_execution`

Table d'une seule ligne (`id = 1`, PK QGIS) traçant le contexte du run, sans dépendance aux tables sources.

| Colonne | Type | Provenance |
|---|---|---|
| `id` | `int4` | Constante `1` |
| `date_donnees` | `date` | Variable `grace_date_donnees` — `NULL` si non renseignée |
| `date_execution` | `timestamptz` | `run_started_at` (démarrage du run dbt, UTC) |
| `container_level` | `text` | Variable `grace_container_level` |
| `srid` | `int4` | Variable `grace_srid` |

GRACE THD ne portant pas de millésime au niveau du jeu, la date des données est saisie manuellement, au run ou dans le `dbt_project.yml` du consommateur :

```bash
dbt run --vars '{grace_date_donnees: 2026-07-01}'
```

Le format `YYYY-MM-DD` est validé en Jinja : un format invalide **arrête le run** (`exceptions.raise_compiler_error`). Exception assumée au principe non-bloquant du package, qui vise les données sources et non un paramètre saisi à la main.

---

## Configuration dbt

### Configuration centralisée (dbt_project.yml)

```yaml
models:
  grace_thd:
    transformations:
      +schema: transformations
      +tags: ["grace_transfo"]  # Tag global sur toutes les transformations
      base:
        +materialized: table
        +tags: ["grace_base"]
      elementaires:
        +materialized: view  # Par défaut : vues
        +tags: ["grace_elem"]
      thematiques:
        +schema: transformations
```

### Override de matérialisation par l'utilisateur

Les utilisateurs du package peuvent surcharger la matérialisation **par modèle** dans leur `dbt_project.yml` :

```yaml
models:
  grace_thd:
    transformations:
      elementaires:
        elem_bp:
          +materialized: table  # Force la matérialisation en table
        elem_cb:
          +materialized: table
        # Les autres restent en view
```


### Chaîne de dépendances complète

```
Sources (gracethd_source)
    ↓
Base (23 tables : t_*)  -- typage non-bloquant + index + PK
    ↓
Élémentaires (18 vues : elem_*)  -- jointures + géométrie projetée
    ↓
Thématiques (models custom)  -- agrégations métiers
```
