# GRACE THD — contrôle qualité & transformation des réseaux fibre

**Un projet [dbt](https://www.getdbt.com/) pour contrôler et exploiter les données de réseaux fibre optique au format [GRACE THD](https://anct.gouv.fr/ressources/publications/recommandations-modelisation-des-reseaux-gracethd) (v3.0.1).**

Vous avez des données GRACE THD (GeoPackage, shapefiles ou CSV) et vous voulez :
vérifier leur conformité au modèle, obtenir un **rapport d'erreurs géolocalisé** exploitable
dans QGIS, et produire des **vues métier** prêtes pour le SIG — **plans de boîtes**, **routes
optiques**, **calcul de capacité du réseau** — le tout **sans qu'une donnée imparfaite ne
bloque le traitement**. C'est exactement ce que fait ce projet.

---

## À propos


Ce projet a été développé par **[digi-studio](https://digi-stud.io)** dans le cadre d'un projet
financé par **[Gironde Numérique](https://www.gironde-numerique.fr)**, et mis à disposition en
**open source**.

Besoin d'un accompagnement ou d'une mise en place sur votre territoire ?
[Contactez digi-studio](https://airtable.com/appjaB6cZweJiwzCm/pagEEKksx1XU6yPCe/form).

<p align="center">
  <a href="https://digi-stud.io"><img src="assets/logo-digi-icon-neutral.svg" alt="digi-studio" height="64"></a>
  &nbsp;&nbsp;&nbsp;&nbsp;
  <a href="https://www.gironde-numerique.fr"><img src="assets/logo-gironde-numerique.png" alt="Gironde Numérique" height="64"></a>
</p>

---

## Par où commencer ?

Ce dépôt est à la fois un **projet dbt exécutable tel quel** (avec un échantillon de données
inclus) **et un package dbt réutilisable** dans votre propre projet. Choisissez votre parcours :

| Votre profil | Parcours conseillé |
|---|---|
| **Vous découvrez dbt / vous voulez juste voir le résultat** | → [Quick Start Docker](#quick-start-docker) : une seule commande, zéro configuration. |
| **Vous voulez faire tourner le projet sur vos données / l'étendre** | → [Quick Start Standalone](#quick-start-standalone) : clonez et lancez sur votre PostGIS. |
| **Vous êtes utilisateur dbt et voulez l'intégrer** | → [Quick Start Package](#quick-start-package) : ajoutez-le à votre `packages.yml`. |

> **Qu'est-ce que dbt ?** [dbt](https://docs.getdbt.com/docs/introduction) (data build tool) est
> un outil qui exécute des transformations SQL versionnées sur une base de données. Ici, il
> orchestre les contrôles qualité et les transformations sur une base **PostgreSQL/PostGIS**.
> Si tout cela est nouveau pour vous, prenez le [parcours Docker](#quick-start-docker) : il
> installe et lance tout pour vous.

---

## Quick Start Docker

Le moyen le plus rapide de voir le projet à l'œuvre. **Seul prérequis : [Docker](https://docs.docker.com/get-docker/).**

```bash
git clone <URL_DU_DEPOT> grace_thd
cd grace_thd
docker compose up --build
```

Cette commande :

1. démarre une base **PostGIS**,
2. importe l'**échantillon public** fourni (`input_data/`),
3. exécute tout le pipeline dbt (contrôles → rapports → transformations),
4. affiche un **résumé du rapport de contrôles**,
5. **laisse la base en ligne** pour l'inspecter.

Une fois le pipeline terminé, la base reste disponible :

```
host=localhost  port=5433  db=grace  user=grace  pass=grace
Schémas : gracethd_source · grace_controles · grace_transformations
```

**Brancher QGIS** : nouvelle connexion PostGIS sur `localhost:5433` (identifiants ci-dessus),
puis chargez `grace_controles.rapport_controles_geo` (erreurs géolocalisées) ou une table
`grace_transformations.elem_*`.

> Pour lancer le pipeline sur **vos** données, remplacez le contenu de `input_data/`
> (voir [`input_data/README.md`](input_data/README.md)) puis relancez `docker compose up --build`.

---

## Quick Start Standalone

Pour faire tourner le projet sur **votre propre base PostGIS**, sans Docker.

**Prérequis** : [uv](https://docs.astral.sh/uv/) (gère Python et les dépendances),
`ogr2ogr` (GDAL) et `psql`, une base **PostgreSQL/PostGIS**.

```bash
git clone <URL_DU_DEPOT> grace_thd
cd grace_thd
uv sync          # crée le venv et installe dbt-postgres + dépendances (pyproject.toml / uv.lock)
```

Configurez un profil dbt `grace_thd` dans `~/.dbt/profiles.yml` pointant vers votre base
(voir [`docker/profiles.yml`](docker/profiles.yml) comme modèle). Puis (les commandes sont
préfixées par `uv run` pour s'exécuter dans le venv du projet) :

```bash
# 1. Importer les données (l'échantillon fourni, ou les vôtres dans input_data/)
uv run python scripts/import_grace_pg.py input_data <votre_cible>

# 2. Charger les paramètres de contrôle
uv run dbt seed

# 3. Contrôles + rapports consolidés (invocations séparées : voir note ci-dessous)
uv run dbt run --select tag:grace_control
uv run dbt run --select tag:grace_rapport

# 4. Transformations
uv run dbt run --select tag:grace_base tag:grace_elem tag:grace_thematiques

# Alternative : toutes les transformations via le tag global
uv run dbt run --select tag:grace_transfo
```

> **Note** : `rapport_controles` agrège les contrôles via `graph.nodes` (sans `ref()`), il n'a
> donc pas de dépendance dbt sur eux et doit être lancé **après** dans une invocation séparée.
>
> **Import** : le script détecte automatiquement un `.gpkg` ou un dossier de shapefiles/CSV.
> Détails : [Guide d'import des données](IMPORT_SCRIPT.md).

---

## Quick Start Package

Pour **intégrer** les contrôles et transformations GRACE THD dans votre projet dbt existant.

**`packages.yml`**
```yaml
packages:
  - git: "<URL_DU_DEPOT>"
    revision: main   # ou un tag spécifique (recommandé)
```

```bash
dbt deps --upgrade
```

Le package est cloné dans `dbt_packages/grace_thd/`. Vous disposez alors des modèles, macros,
seeds et du script d'import. Configuration, overrides et exemples :
[Guide d'utilisation du package](UTILISATION_PACKAGE.md).

---

## Philosophie : intégration non bloquante

Le package suit une approche en **trois étapes** pour une intégration progressive des données :

```
1. Intégration non bloquante   → données acceptées telles quelles, même imparfaites
2. Contrôle exhaustif          → vérification systématique, rapport d'erreurs détaillé
3. Nettoyage & transformations → typage cohérent, préparation pour l'exploitation SIG
```

| Type d'erreur | Traitement |
|--------------|------------|
| Champ typé en `string` au lieu de `integer` | Accepté en intégration, corrigé en transformation |
| Valeur aberrante (ex. longueur négative) | Identifiée dans les contrôles, remontée dans le rapport |
| Donnée fortement erronée (ex. géométrie invalide) | Impacte certaines transformations sans arrêter le processus |

> L'échantillon fourni est volontairement imparfait (v3.0 vs v3.0.1 ciblée) : idéal pour
> illustrer des contrôles qui **signalent** les anomalies au lieu de les masquer.

---

## Architecture globale

Le package est organisé en **deux grands modules** :

```
GRACE THD (dbt)
├── Contrôles de qualité
│   ├── Génériques (paramétrables via seeds)
│   │   └── présence des tables · remplissage · unicité · clés étrangères
│   │       · listes de valeurs · vérification de types
│   └── Spécifiques (règles métiers / topologiques)
│       └── remplissage conditionnel · topologie/géométrie · règles métiers
│
└── Transformations
    ├── Base (23 tables)      → typage non bloquant + clés primaires + index
    ├── Élémentaires (18 vues) → jointures et projections géométriques
    └── Thématiques            → plans de boîtes, routes optiques, capacité réseau
```

> **Pour aller plus loin** :
> [Architecture des contrôles](ARCHITECTURE_CONTROLES.md) ·
> [Architecture des transformations](ARCHITECTURE_TRANSFORMATIONS.md)

---

## Configuration

| Variable | Défaut | Description |
|----------|--------|-------------|
| `grace_container_level` | `C4` | Conteneur ciblé par les contrôles — phase du cycle de vie (C1 à C4, voir [Concepts clés](#conteneurs-c1-à-c4)) |
| `grace_srid` | `2154` | SRID des géométries (RGF93 / Lambert-93). Source de vérité unique : typage geom des modèles **et** DDL des sources (`scripts/generate_source_schema.py`) |

```yaml
# dbt_project.yml
vars:
  grace_container_level: "C2"
```

**Personnalisation** :
- **Ajouter un contrôle** : créez un modèle avec `tags=['grace_control']` — il est
  automatiquement inclus dans `rapport_controles`.
- **Changer la matérialisation** : passez des vues en tables via la config dbt.

> Détails : [Guide d'utilisation du package](UTILISATION_PACKAGE.md).

---

## Résultats et rapports

Tous les contrôles produisent un **schéma unifié** à 7 colonnes :

| Colonne | Description |
|---------|-------------|
| `id_test` | Identifiant unique du contrôle |
| `type_controle` | Catégorie du contrôle |
| `description` | Libellé du contrôle |
| `classe` | Table principale concernée |
| `attribut` | Attribut contrôlé |
| `id_entite` | Identifiant de l'entité en erreur |
| `detail_erreur` | Détails spécifiques sur l'erreur |

**Rapports consolidés** :
- **`rapport_controles`** : table consolidant tous les résultats de contrôles.
- **`rapport_controles_geo`** : le même rapport, **géolocalisé** (géométrie native : point, ligne ou polygone selon la classe ; chargeable dans QGIS).
- **`rapport_controles_geo_as_line`** : le même rapport, toutes les géométries ramenées à un type ligne homogène pour une couche QGIS unique (voir [Architecture des contrôles](ARCHITECTURE_CONTROLES.md)).

---

## Concepts clés

### Conteneurs (C1 à C4)

Un **conteneur** est un lot de données GRACE THD correspondant à une **phase du cycle de vie**
du réseau BLOM (les tables et champs retenus varient selon la phase) :

| Conteneur | Phase |
|-----------|-------|
| `C1` | Pavage et couverture du territoire |
| `C2` | Ingénierie et conception du réseau |
| `C3` | Passage du déploiement à l'exploitation / commercialisation |
| `C4` | Maintien en condition opérationnelle |

Les contrôles s'activent selon le conteneur ciblé (`grace_container_level`, **`C4` par défaut**) :
chaque contrôle est paramétrable pour s'appliquer à un ou plusieurs conteneurs.

### Typage non bloquant

La couche **Base** utilise un pattern de typage tolérant :

```sql
CASE
  WHEN pg_input_is_valid(NULLIF(champ::text, ''), 'type_postgres')
  THEN champ::TYPE
  ELSE NULL
END AS alias
```

Il accepte les valeurs vides (→ NULL), ne bloque pas sur une erreur de typage, et garantit un
schéma de sortie stable.

### Géométrie et transformations

Les transformations **Élémentaires** projettent la géométrie sur toutes les entités :
projection directe (1:1), chaînée (multi-niveaux, ex. `t_local → t_site → t_noeud`), complexe
(`MakeLine`, `COALESCE`, `UNION`) ou hiérarchique.

---

## Structure du projet

```
grace_thd/
├── input_data/             # jeu de données d'entrée (échantillon public par défaut)
├── docker/                 # Dockerfile, profiles.yml, entrypoint du parcours Docker
├── docker-compose.yml
├── models/
│   ├── controls/           # génériques + spécifiques + rapports consolidés
│   └── transformations/    # base · élémentaires · thématiques
├── seeds/                  # paramètres des contrôles + listes de valeurs
├── macros/                 # macros de contrôles et helpers
├── scripts/                # import_grace_pg.py et utilitaires
└── dbt_project.yml
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [`input_data/README.md`](input_data/README.md) | Jeu de données d'entrée : formats, remplacement, échantillon |
| [Architecture des contrôles](ARCHITECTURE_CONTROLES.md) | Détails techniques des contrôles |
| [Architecture des transformations](ARCHITECTURE_TRANSFORMATIONS.md) | Détails techniques des transformations |
| [Utilisation du package](UTILISATION_PACKAGE.md) | Installation, configuration, overrides |
| [Import des données](IMPORT_SCRIPT.md) | Documentation du script d'import |
| [CHANGELOG](CHANGELOG.md) | Historique des versions |

---

## Licence

Ce projet est distribué sous licence **MIT** — voir le fichier [`LICENSE`](LICENSE).


Contexte du projet et accompagnement : voir [À propos](#à-propos).
