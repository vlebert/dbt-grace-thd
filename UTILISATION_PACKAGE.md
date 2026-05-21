# Utilisation du package DBT pour GRACE THD

**Guide pratique pour l'installation, la configuration et l'utilisation du package**

> **Pour une présentation générale** : [Retour au README](README.md)

---

## Installation

Dans le projet consommateur, ajouter le dépôt comme dépendance :

**`packages.yml`**
```yaml
packages:
  - git: "git@gitlab.com:<org>/grace_thd.git"
    revision: main  # ou un tag (recommandé : v1.0.0)
```

Puis installer :
```bash
dbt deps
```

> **Authentification GitLab privé** : utiliser une clé SSH ou un token HTTPS.
> Exemple HTTPS : `git: "https://oauth2:<token>@gitlab.com/<org>/grace_thd.git"`

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
python dbt_packages/grace_thd/scripts/import_grace_pg.py /chemin/vers/NA-16025-BGNR dev
```

Le script lit automatiquement les identifiants de connexion depuis `~/.dbt/profiles.yml` (cible `dev` dans cet exemple).

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

### 2. Seeds

| Action | Emplacement | Comportement |
|---|---|---|
| **Surcharger une seed** | `seeds/<nom>.csv` | Écrase celle du package |
| **Ajouter une seed** | `seeds/...` | Nouvelle seed disponible |

Exemple : surcharger `param_ctrl_remplissage.csv` avec vos propres paramètres :
```bash
cp dbt_packages/grace_thd/seeds/controls/param_ctrl_remplissage.csv seeds/controls/
# Modifier seeds/controls/param_ctrl_remplissage.csv
```

### 3. Variables

| Variable | Default | Usage |
|---|---|---|
| `grace_container_level` | `C3` | Niveau de conteneur pour les contrôles |
| `grace_ctrl_models_ext` | `[]` | Liste de modèles de contrôle à ajouter |

Exemple : ajouter des contrôles personnalisés + changer le niveau :
```yaml
# dbt_project.yml du consommateur
vars:
  grace_container_level: "C2"
  grace_ctrl_models_ext:
    - mon_controle_custom
    - un_autre_controle
```
