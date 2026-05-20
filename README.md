# Package DBT pour GRACE THD

**Outil de contrôle qualité et de transformation pour les données GRACE THD**

---

## Presentation

> **GRACE THD V3.0.1** est un **modèle de données relationnel** pour modéliser les réseaux en fibre optique jusqu'à l'abonné. Il définit la structure standard des données pour décrire les infrastructures télécoms.

**Ce projet** est un **package DBT** conçu pour être intégré dans d'autres projets DBT. Il permet de :

- **Contrôler** la qualité des données selon les standards et règles métiers du modèle GRACE THD
- **Transformer** les données pour les rendre exploitables dans les outils SIG (QGIS, etc.)
- **Intégrer** les données de manière **non bloquante**, permettant une analyse progressive

---

## Philosophie d'integration

Le package suit une approche en **trois étapes** pour garantir une intégration fluide et progressive des données :

```
1. Intégration non bloquante
    ├── Données acceptées même avec des erreurs
    ├── Pas de blocage immédiat sur les anomalies
    └── Priorité à la disponibilité des données

2. Contrôle exhaustif
    ├── Vérification systématique des règles
    ├── Identification précise des erreurs
    └── Génération de rapports détaillés

3. Nettoyage et transformations
    ├── Correction des erreurs mineures
    ├── Typage cohérent des données
    └── Préparation pour l'exploitation
```

### Exemple concret

| Type d'erreur | Traitement |
|--------------|------------|
| Champ typé en `string` au lieu de `integer` | Accepté en intégration, corrigé en nettoyage |
| Valeur aberrante (ex: longueur négative) | Identifiée dans les contrôles, rapport généré |
| Donnée fortement erronée (ex: géométrie invalide) | Impacte certaines transformations, mais n'arrête pas le processus |

---

## Architecture globale

Le package est organisé en **deux grands modules** :

```
Package DBT pour GRACE THD
├── Contrôles de qualité
│   ├── Génériques (paramétrables via seeds)
│   │   ├── Présence des tables
│   │   ├── Remplissage obligatoire
│   │   ├── Unicité
│   │   ├── Clés étrangères
│   │   ├── Listes de valeurs
│   │   └── Vérification de types
│   └── Spécifiques (règles métiers/topologiques)
│       ├── Remplissage conditionnel
│       ├── Topologie/géométrie
│       └── Règles métiers
│
└── Transformations
    ├── Base (23 tables)
    │   └── Typage non-bloquant + clés primaires + index
    ├── Élémentaires (18 vues)
    │   └── Jointures et projections géométriques
    └── Thématiques
        └── Transformations avancées (à venir)
```

> **Pour aller plus loin** :
> - [Architecture détaillée des contrôles](ARCHITECTURE_CONTROLES.md)
> - [Architecture détaillée des transformations](ARCHITECTURE_TRANSFORMATIONS.md)

---

## Utilisation rapide

### 1. Installation du package

Dans votre projet DBT, ajoutez la dépendance dans `packages.yml` :

```yaml
packages:
  - git: "git@gitlab.com:<org>/grace_thd.git"
    revision: main  # ou un tag spécifique (recommandé)
```

Puis installez :
```bash
dbt deps
```

### 2. Import des données

Utilisez le script fourni pour importer vos données GRACE THD :

```bash
python dbt_packages/grace_thd/scripts/import_grace_pg.py /chemin/vers/vos/donnees.gpkg
```

> **Prérequis** : Python 3, `ogr2ogr` (GDAL), `psql`, profil DBT configuré
> **Plus d'infos** : [Guide d'import des données](IMPORT_SCRIPT.md)

### 3. Exécution des contrôles

```bash
# Exécuter tous les contrôles
dbt run --select tag:control

# Générer le rapport consolidé
dbt run --select rapport_controles

# Avec géolocalisation
dbt run --select rapport_controles_geo
```

### 4. Exécution des transformations

```bash
# Générer les tables base
dbt run --select tag:base

# Générer les vues élémentaires
dbt run --select tag:elem
```

---

## Configuration

### Variables principales

| Variable | Valeur par défaut | Description |
|----------|-------------------|-------------|
| `grace_container_level` | `C3` | Niveau de conteneur pour les contrôles (C1 à C4) |
| `grace_ctrl_models_ext` | `[]` | Liste de modèles de contrôle personnalisés à ajouter |

Exemple dans `dbt_project.yml` :
```yaml
vars:
  grace_container_level: "C2"
  grace_ctrl_models_ext:
    - mon_controle_custom
    - un_autre_controle
```

### Personnalisation

Vous pouvez :
- **Surcharger des seeds** : Copiez les fichiers CSV dans votre projet et modifiez-les
- **Ajouter des contrôles** : Via la variable `grace_ctrl_models_ext`
- **Changer la matérialisation** : Passez des vues en tables via configuration DBT

> **Plus d'infos** : [Guide d'utilisation du package](UTILISATION_PACKAGE.md)

---

## Resultats et rapports

### Sortie des contrôles

Tous les contrôles produisent un **schéma unifié** avec 7 colonnes :

| Colonne | Description |
|---------|-------------|
| `id_test` | Identifiant unique du contrôle |
| `type_controle` | Catégorie du contrôle |
| `description` | Libellé du contrôle |
| `classe` | Table principale concernée |
| `attribut` | Attribut contrôlé |
| `id_entite` | Identifiant de l'entité en erreur |
| `detail_erreur` | Détails spécifiques sur l'erreur |

### Rapports consolidés

- **`rapport_controles`** : Table consolidant tous les résultats de contrôles
- **`rapport_controles_geo`** : Même rapport avec géolocalisation des erreurs

---

## Structure du projet

```
grace_thd/
├── models/
│   ├── controls/
│   │   ├── generique/          # Contrôles génériques
│   │   │   ├── ctrl_presence_table.sql
│   │   │   ├── ctrl_remplissage.sql
│   │   │   ├── ctrl_unicite.sql
│   │   │   ├── ctrl_fk.sql
│   │   │   ├── ctrl_liste_valeur.sql
│   │   │   └── ctrl_type.sql
│   │   ├── specifique/          # Contrôles spécifiques
│   │   │   ├── remplissage_cond/
│   │   │   ├── topologie/
│   │   │   └── metier/
│   │   ├── rapport_controles.sql
│   │   └── rapport_controles_geo.sql
│   └── transformations/
│       ├── base/              # Tables base (23)
│       ├── elementaires/      # Vues élémentaires (18)
│       └── thematiques/        # Transformations avancées
├── seeds/
│   ├── controls/              # Paramètres des contrôles
│   │   ├── param_ctrl_*.csv
│   └── listes/                 # Listes de valeurs (44 tables)
├── macros/
│   └── controls/              # Macros pour les contrôles
├── scripts/                   # Scripts utilitaires
│   ├── import_grace_pg.py
│   └── ...
└── dbt_project.yml            # Configuration centrale
```

---

## Concepts clés

### Niveaux de conteneur (C1 à C4)

Les contrôles peuvent être activés/désactivés selon le **niveau de conteneur** :

| Niveau | Description |
|--------|-------------|
| C1 | Conteneur de niveau 1 (le plus haut) |
| C2 | Conteneur de niveau 2 |
| C3 | **Niveau par défaut** |
| C4 | Conteneur de niveau 4 (le plus bas) |

Chaque contrôle est paramétrable pour s'appliquer à un ou plusieurs niveaux.

### Typage non-bloquant

Les transformations de la couche **Base** utilisent un pattern de typage tolérant :

```sql
CASE 
  WHEN pg_input_is_valid(NULLIF(champ::text, ''), 'type_postgres') 
  THEN champ::TYPE 
  ELSE NULL 
END AS alias
```

Cela permet :
- D'accepter les valeurs vides (converties en NULL)
- De ne pas bloquer sur des erreurs de typage
- De garantir un schéma stable

### Géométrie et transformations

Les transformations **Élémentaires** projettent la géométrie sur toutes les entités :

- **Projection directe** : Jointure 1:1 table → géométrie
- **Chaînée** : Jointure multi-niveaux (ex: t_local → t_site → t_noeud)
- **Complexe** : Géométrie construite (MakeLine, COALESCE, UNION)
- **Hiérarchique** : Combinaison de plusieurs sources

---


## Documentation complète

| Document | Description |
|----------|-------------|
| [README.md](README.md) | **Ce document** - Vue d'ensemble du package |
| [Architecture des contrôles](ARCHITECTURE_CONTROLES.md) | Détails techniques des contrôles |
| [Architecture des transformations](ARCHITECTURE_TRANSFORMATIONS.md) | Détails techniques des transformations |
| [Utilisation du package](UTILISATION_PACKAGE.md) | Guide d'installation et configuration |
| [Import des données](IMPORT_SCRIPT.md) | Documentation du script d'import |
