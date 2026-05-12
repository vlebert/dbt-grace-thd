# Architecture des Transformations GRACE THD

## Vue d'ensemble

Les transformations GRACE THD sont organisées en **trois couches** avec une chaîne de dépendances claire :

1. **Base** (`base/`) — 23 tables avec typage non-bloquant, clés primaires et index
2. **Élémentaires** (`elementaires/`) — 18 vues (par défaut) construites sur les tables base, avec possibilité d'override en `table`
3. **Thématiques** (`thematiques/`) — Transformations avancées par thème métier (à venir)

---

## Couche Base

**Dossier** : `models/transformations/base/`

**Rôle** : Répliquer les tables sources du schéma `gracethd_source` dans le schéma `transformations` avec :
- **Typage non-bloquant** via `pg_input_is_valid(NULLIF(champ::text, ''), 'type_postgres')`
- **Nettoyage des valeurs vides** : les chaînes vides (`''`) sont converties en `NULL` avant validation
- **Clé primaire technique** : colonne `id` (integer) générée via `row_number() OVER (ORDER BY pk_naturelle)`
- **Index** : index btree sur toutes les colonnes pertinentes + index gist sur `geom` pour les tables spatiales
- Conservation intacte de la colonne `geom` pour les 10 tables spatiales

**Pattern de typage non-bloquant** :
```sql
CASE WHEN pg_input_is_valid(NULLIF(champ::text, ''), 'type_postgres')
     THEN champ::TYPE ELSE NULL END AS alias
```

**Configuration standard** :
```sql
{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['base'],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['colonne_1'], 'type': 'btree'},
            {'columns': ['colonne_2'], 'type': 'btree'},
            {'columns': ['geom'], 'type': 'gist'},  -- pour les tables spatiales
        ]
    )
}}
```

**Tables avec colonne `geom`** (10/23) :
t_adresse, t_cableline, t_cheminement, t_noeud, t_point_leve, t_pointaccueil, t_tranchee, t_zdep, t_znro, t_zsro

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
| **Matérialisation** | `view` **par défaut**, override possible en `table` via `dbt_project.yml` |
| **Tags** | `elem` sur tous les modèles |
| **Schéma** | `transformations` |
| **Documentation** | 1 fichier `.yml` par modèle |
| **Géométrie** | `geom AS geom` en dernière colonne |
| **Clé primaire** | `id` héritée de la table base source |

> **Note QGIS** : La colonne `id` (integer) est **sourcée depuis les tables base** via `{alias}.id`, offrant une clé primaire stable sans régénération.

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

---

## Couche Thématique

**Dossier** : `models/transformations/thematiques/`

Réservé pour les transformations avancées par thème métier (ex: dimensionnement, topologie, rapports).
À développer ultérieurement.

---

## Configuration dbt

### Configuration centralisée (dbt_project.yml)

```yaml
models:
  grace_thd:
    transformations:
      +schema: transformations
      base:
        +materialized: table
        +tags: ["base"]
      elementaires:
        +materialized: view  # Par défaut : vues
        +tags: ["elem"]
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
