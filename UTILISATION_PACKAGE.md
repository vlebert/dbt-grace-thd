# Utilisation du package DBT pour GRACE THD

**Guide pratique pour l'installation, la configuration et l'utilisation du package**

> **Pour une présentation générale** : [Retour au README](README.md)

---

## Installation

Dans le projet consommateur, ajouter le dépôt comme dépendance :

**`packages.yml`**
```yaml
packages:
  - git: "<URL_DU_DEPOT>"
    revision: main  # ou un tag (recommandé : v1.0.0)
```

Puis installer :
```bash
dbt deps --upgrade
```


Le package est cloné dans :
```
<votre_projet>/
  dbt_packages/
    grace_thd/
      models/
      macros/
      seeds/
      scripts/          # scripts disponibles
      dbt_project.yml
      ...
```

### Mise à jour du package

Pour mettre à jour le package vers la dernière version (ou un tag spécifique après modification de `packages.yml`) :
```bash
dbt deps --upgrade
```

---

## Utilisation des scripts

Les scripts du package (`scripts/`) sont accessibles dans `dbt_packages/grace_thd/`.

### Exemple : import de données sources

```bash
# Depuis la racine du projet consommateur
python dbt_packages/grace_thd/scripts/import_grace_pg.py "/chemin/vers/mes_donnees" dev
```

Le script lit automatiquement les identifiants de connexion depuis `~/.dbt/profiles.yml` (cible `dev` dans cet exemple) et détecte le format de la source (`.gpkg`, ou dossier de shapefiles/CSV). Un échantillon public prêt à l'emploi est fourni dans `input_data/` (voir le [README dédié](input_data/README.md)).

---

## Overrides (surcharge)

### 1. Modèles

| Type | Emplacement | Commentaire |
|---|---|---|
| **Nouveau modèle** | `models/` | Ajout simple, automatiquement détecté |
| **Override modèle existant** | `models/grace_thd/<chemin>/<fichier>.sql` | Same path, écrasement |

Exemple : surcharger `elem_bp` (vue → table) :
```yaml
# dbt_project.yml du consommateur
models:
  grace_thd:
    transformations:
      elementaires:
        elem_bp:
          +materialized: table
```

#### Index et clé primaire sur un modèle matérialisé en table

Les modèles élémentaires sont livrés en vue : le planificateur PostgreSQL les
« inline » et exploite directement les index des tables `t_*` sous-jacentes. En
basculant un modèle en table, ce bénéfice disparaît — il faut redéclarer les index
utiles, et une clé primaire pour QGIS (sans elle, QGIS retombe sur le `ctid`,
instable dès le premier `UPDATE` ou `VACUUM`).

Les deux réglages se posent au même niveau que `+materialized` :
```yaml
# dbt_project.yml du consommateur
models:
  grace_thd:
    transformations:
      elementaires:
        +materialized: table
        # Tous les modèles élémentaires exposent une colonne `id`.
        +post-hook:
          - "ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"
        elem_ps_cs:
          +indexes:
            - columns: ['ps_code']
              type: btree
            - columns: ['geom']
              type: gist
```

Points d'attention :

- **`+indexes` remplace, ne fusionne pas.** Contrairement aux hooks et aux tags qui
  s'accumulent entre niveaux, une liste d'index déclarée écrase intégralement celle
  du niveau inférieur.
- **Les colonnes indexées doivent être projetées par le modèle.** Un index sur une
  colonne d'une table amont non reprise dans le `SELECT` final fait échouer le run.
- **La clé primaire échoue si `id` contient des doublons ou des `NULL`.** Plusieurs
  élémentaires construisent leur `id` via une jointure : un défaut d'unicité dans les
  données d'entrée transforme alors un problème qualité en échec de run. Lancez
  `dbt test --select <modèle>` (les tests `unique` / `not_null` sur `id` sont déjà
  déclarés) avant d'activer le post-hook. En cas de doute, remplacez-le par un index
  non unique :
  ```yaml
  +indexes:
    - columns: ['id']
      type: btree
  ```
- **Ces déclarations sont inertes tant que le modèle reste en vue** : la config
  `+indexes` est ignorée par la matérialisation `view`. Le `+post-hook`, en revanche,
  échoue sur une vue — ne le posez qu'aux niveaux effectivement basculés en table.

### 2. Variables

| Variable | Default | Usage |
|---|---|---|
| `grace_container_level` | `C4` | Conteneur ciblé par les contrôles (phase du cycle de vie C1–C4) |
| `grace_date_donnees` | *(non renseignée)* | Date du jeu de données source (`YYYY-MM-DD`), exposée par `meta_execution` |

Exemple : changer le niveau de conteneur :
```yaml
# dbt_project.yml du consommateur
vars:
  grace_container_level: "C2"
```

Une variable peut aussi être fournie **au moment du run**, ce qui est le mode d'emploi
attendu pour `grace_date_donnees` (valeur propre à chaque livraison) :
```bash
dbt run --vars '{grace_date_donnees: 2026-07-01}'
```
Le format `YYYY-MM-DD` est obligatoire : toute autre écriture (`01/07/2026`, …) arrête
le run avec un message explicite, plutôt que d'enregistrer une date mal interprétée.

### Ajouter des contrôles personnalisés

Créez un modèle de contrôle dans votre projet en respectant le schéma unifié à 7 colonnes et appliquez-lui le tag `grace_control`. Il sera automatiquement inclus dans `rapport_controles` sans aucune configuration supplémentaire.

```sql
-- models/mon_controle_custom.sql
{{ config(materialized='table', tags=['grace_control']) }}

{{ grace_thd.ctrl_specifique(
    id_test       = 'metier_9001',
    type_controle = 'regle_metier',
    classe        = 'ma_table',
    cle_primaire  = 'ma_pk',
    attribut      = 'mon_attribut',
    description   = 'Description du contrôle',
    requ_princ    = 'SELECT ma_pk, mon_attribut FROM ' ~ source('gracethd', 'ma_table'),
    condition     = 'src.mon_attribut IS NULL'
) }}
```
