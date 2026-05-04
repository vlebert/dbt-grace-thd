# Architecture des Transformations GRACE THD

## Vue d'ensemble

Les transformations GRACE THD sont organisées en deux grands ensembles :

1. **Vues élémentaires** (`elementaires/`) — Les jointures de base du modèle GRACE THD qui projettent une géométrie sur des tables qui n'en ont pas, via les jointures nécessaires.
2. **Thématiques** (`thematiques/`) — Transformations avancées par thème métier (à venir).

## Vues Élémentaires

**Dossier** : `models/transformations/elementaires/`

**Rôle** : Effectuer des jointures et des filtrages élémentaires sur les tables sources (t_site, t_ebp, t_local, etc.) afin de projeter une géométrie (`geom`) et de fournir une base pour les transformations ultérieures.

### Conventions

| Élément | Règle |
|---|---|
| **Préfixe** | `elem_` (remplace `vs_elem_` legacy) |
| **Matérialisation** | `table` (matérialisé pour performances) |
| **Tags** | `elem` sur tous les modèles |
| **Schéma** | `transformations` |
| **Documentation** | 1 fichier `.yml` par modèle |
| **Géométrie** | Toujours `geom AS geom` en dernière colonne |
| **Clé primaire** | `id` (bigint) générée via `row_number() OVER (ORDER BY pk_source)` pour QGIS |

> **Note** : Ces tables sont amenées à être consommées par QGIS, il faut donc idéalement une clé primaire de type integer. La colonne `id` technique est générée via `row_number() OVER (ORDER BY pk_source)`.

### Typologie

| Catégorie | Description | Exemples |
|---|---|---|
| **Base** | Jointure directe 1:1 table → géométrie | elem_st_nd, elem_pt_nd, elem_cl_cb |
| **Chaînée** | Jointure multi-niveaux (2-4 tables) | elem_lc_st_nd, elem_bp_lc_st_nd, elem_ba_lc_st_nd |
| **Complexe** | Géométrie construite (UNION/COALESCE/MakeLine) | elem_cb, elem_bp |
| **Hiérarchique** | UNION ALL de plusieurs sources | elem_cs, elem_ps |
| **Filtrage** | Avec conditions métier spécifiques | elem_pto |

### Liste des modèles (18)

| Modèle | Description |
|---|---|
| `elem_st_nd` | t_site → t_noeud |
| `elem_lc_st_nd` | t_local → t_site → t_noeud |
| `elem_bp_lc_st_nd` | t_ebp → t_local → t_site → t_noeud (INNER JOIN lc) |
| `elem_bp_pt_nd` | t_ebp → t_ptech → t_noeud |
| `elem_pt_nd` | t_ptech → t_noeud |
| `elem_cl_cb` | t_cable → t_cableline |
| `elem_cb` | t_cable : UNION ALL (cableline OU MakeLine(nd1, nd2)) |
| `elem_bp` | t_ebp (PBO/BPE) : COALESCE géométrie pt ou st |
| `elem_pto` | t_ebp (PTO) → t_adresse, filtre `bp_typelog = 'PTO' AND st_typelog = 'CLIENT'` |
| `elem_ba_lc_st_nd` | t_baie → t_local → t_site → t_noeud |
| `elem_ti_ba_lc_st_nd` | t_tiroir → t_baie → t_local → t_site → t_noeud |
| `elem_fo_cb_cl` | t_fibre → t_cable → t_cableline |
| `elem_cs_bp` | t_cassette → ref(elem_bp) |
| `elem_cs_ti` | t_cassette → ref(elem_ti), via t_position, WHERE cs_bp_code IS NULL |
| `elem_cs` | UNION ALL elem_cs_bp + elem_cs_ti |
| `elem_ps_cs` | t_position → ref(elem_cs) |
| `elem_ps_ti` | t_position → ref(elem_ti) |
| `elem_ps` | UNION ALL elem_ps_cs + elem_ps_ti |

### Jointures et particularités

- **LEFT JOIN** : Utilisé par défaut pour les relations optionnelles
- **INNER JOIN** : Utilisé quand la relation est obligatoire (ex: `bp.bp_lc_code = lc.lc_code` dans elem_bp_lc_st_nd)
- **COALESCE** : Pour gérer plusieurs sources de géométrie possibles (elem_bp : pt OU st)
- **ST_MakeLine** : Pour construire une géométrie à partir de points (elem_cb : nd1 → nd2)
- **UNION ALL** : Pour combiner plusieurs sources (elem_cb, elem_cs, elem_ps)
- **Filtrage** : Conditions métier dans WHERE (ex: `bp_typelog = 'PTO' AND st_typelog = 'CLIENT'` dans elem_pto)

### Clé primaire technique

Toutes les tables incluent une colonne `id` (bigint) générée via :
```sql
row_number() OVER (ORDER BY [clé_primaire_source]) AS id
```

Exemples :
- `elem_st_nd` : `ORDER BY st.st_code`
- `elem_cb` : `ORDER BY cb.cb_code`
- `elem_pto` : `ORDER BY bp.bp_code, bp.bp_statut`

Cette colonne permet à QGIS d'avoir une clé primaire stable pour gérer les données.

## Thématiques

**Dossier** : `models/transformations/thematiques/`

Réservé pour les transformations avancées par thème métier (ex: dimensionnement, topologie, rapport).
À développer ultérieurement.

## Configuration dbt

**dbt_project.yml** :
```yaml
models:
  grace_thd:
    transformations:
      +schema: transformations
      elementaires:
        +materialized: table
        +tags: ["elem"]
      thematiques:
        +schema: transformations
```

## Exécution

### Exécuter tous les modèles élémentaires

```bash
# Par tag (recommandé)
dbt run --select tag:elem

# Par chemin
dbt run --select path:transformations/elementaires

# Par préfixe
dbt run --select elem_
```

### Exécuter un modèle spécifique

```bash
dbt run --select elem_cb
dbt run --select elem_pto
```

### Vérifier avant exécution

```bash
# Compilation seule (vérifie la syntaxe)
dbt compile --select tag:elem

# Forcer le refresh
dbt run --select tag:elem --full-refresh
```

## Usage dans les contrôles

Les vues élémentaires peuvent être utilisées comme sources dans les contrôles :

```sql
FROM {{ ref('elem_bp_lc_st_nd') }} AS bp
```

Cela permet d'accéder directement à la géométrie sans refaire les jointures.
