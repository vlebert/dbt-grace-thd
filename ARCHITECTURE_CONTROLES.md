# Architecture des contrôles GRACE THD

Ce document définit les conventions d'architecture pour l'implémentation des contrôles de qualité de données. Il complète `SPECS_CONTROLES.md` qui décrit le format de résultat unifié.

## Principes directeurs

1. **Schéma de sortie unifié** — tout contrôle produit les 7 colonnes définies dans `SPECS_CONTROLES.md` (`id_test`, `type_controle`, `description`, `classe`, `attribut`, `id_entite`, `detail_erreur`). La géométrie n'est pas portée par les contrôles : elle est résolue en aval dans `rapport_controles_geo` à partir de (`classe`, `id_entite`).
2. **Séparation générique / spécifique**
   - *Générique* : un contrôle reproduit N fois sur des couples (classe, attribut) avec une structure SQL uniforme. Paramétré par seed.
   - *Spécifique* : un contrôle avec une logique SQL propre (jointures, conditions complexes, topologie, règle métier). Un fichier par règle.
3. **Configuration par seeds** — les paramètres des contrôles génériques sont stockés en seeds CSV préfixés `param_ctrl_*`. Un projet consommateur peut les surcharger via le mécanisme dbt standard (seed de même nom dans son propre répertoire).
4. **Consolidation par vars** — le rapport final assemble les contrôles via deux variables dbt (`grace_ctrl_models` pour le package, `grace_ctrl_models_ext` pour les extensions utilisateur). Voir section Consolidation.

## Typologie des contrôles

| Catégorie | Traitement | Modèle |
|---|---|---|
| Présence / vacuité des tables obligatoires | **Générique** | `ctrl_presence_table` |
| Remplissage obligatoire (selon niveau de conteneur) | **Générique** | `ctrl_remplissage` |
| Unicité | **Générique** | `ctrl_unicite` |
| Clé étrangère | **Générique** | `ctrl_fk` |
| Liste de valeurs | **Générique** | `ctrl_liste_valeur` |
| Remplissage conditionnel | **Spécifique** | `ctrl_rc_<id>` |
| Contrôle géométrique / topologique | **Spécifique** | `ctrl_topo_<id>` |
| Règle métier | **Spécifique** | `ctrl_m_<id>` |

## Structure de fichiers

```
models/controls/
  generique/
    ctrl_presence_table.sql     # présence et vacuité des tables obligatoires
    ctrl_remplissage.sql        # attributs obligatoires NULL ou vides
    ctrl_unicite.sql            # doublons sur un attribut
    ctrl_fk.sql                 # intégrité référentielle
    ctrl_liste_valeur.sql       # conformité aux listes de valeurs l_*
  specifique/
    remplissage_cond/
      ctrl_rc_<id>.sql
    topologie/
      ctrl_topo_<id>.sql
    metier/
      ctrl_m_<id>.sql
  rapport_controles.sql         # UNION ALL via vars grace_ctrl_models (sans geom)
  rapport_controles_geo.sql     # rapport_controles + geom résolue par classe

seeds/
  controls/
    param_ctrl_presence_table.csv
    param_ctrl_remplissage.csv
    param_ctrl_unicite.csv
    param_ctrl_fk.csv
    param_ctrl_liste_valeur.csv
  listes/
    l_<nom>.csv                 # listes de valeurs GRACE THD (44 tables)

scripts/
  sql_listes_to_seeds.py              # génère les seeds listes/ depuis les SQL MCD
  generate_param_ctrl_liste_valeur.py # génère param_ctrl_liste_valeur.csv depuis FK SQL
  update_rc_controls.py            # met à jour les contrôles RC avec activation par conteneur
```

## Contrôles génériques

### Principe

Un modèle par type de contrôle. La boucle Jinja lit son seed de paramétrage au moment de l'exécution (`run_query` dans un bloc `{% if execute %}`), puis génère un `UNION ALL` interne — une branche par ligne active. Les tests désactivés (`actif = false`) ne produisent aucun SQL.

Un placeholder `SELECT ... WHERE false` garantit un schéma stable même quand aucun test n'est actif.

### Tolérance aux tables manquantes

Avant de générer les branches SQL, chaque modèle générique filtre les tests dont la table source n'existe pas dans `information_schema.tables`. Les tables absentes sont silencieusement ignorées (elles sont remontées par `ctrl_presence_table`). Le schéma source est résolu via le graph dbt :

```jinja
{%- set src_schema = (graph.sources.values()
      | selectattr('source_name', 'equalto', 'gracethd')
      | list | first).schema -%}
```

### Seeds de paramétrage

Nommage : `param_ctrl_<type>.csv` — préfixe `param_` pour éviter la collision de noms avec les modèles de résultats (`ctrl_*`) dans le `schema.yml` dbt.

Colonnes communes : `id_test`, `classe`, `cle_primaire`, `actif` (booléen).

| Seed | Colonnes spécifiques |
|---|---|
| `param_ctrl_presence_table.csv` | `conteneur_c1..c4` (O/C/N) |
| `param_ctrl_remplissage.csv` | `attribut`, `conteneur_c1..c4` (O/C/N) — inclut aussi les contrôles **RC** (`ctrl_rc_*`) avec `conteneur_cX='C'` pour activation conditionnelle |
| `param_ctrl_unicite.csv` | `attribut` |
| `param_ctrl_fk.csv` | `attribut`, `classe_cible`, `attribut_cible` |
| `param_ctrl_liste_valeur.csv` | `attribut`, `table_liste` (ex. `l_bool`, `l_etat_avancement`) |

### Niveau de conteneur

Variable dbt `grace_container_level` (valeurs `C1`..`C4`, défaut `C3`). Les modèles `ctrl_presence_table` et `ctrl_remplissage` filtrent sur la colonne `conteneur_cX` correspondante et ne déclenchent le contrôle que sur les attributs/tables marqués `O` à ce niveau.

### Listes de valeurs

Les seeds `l_*` sont chargés dans le schéma `<target.schema>_listes` (via `+schema: listes` dans `dbt_project.yml`). Le modèle `ctrl_liste_valeur` y accède via `target.schema ~ '_listes'` — une référence directe au schéma, car les noms de tables sont dynamiques et ne peuvent pas utiliser `ref()`.

### Conventions de nommage des `id_test`

Format : `ctrl_<prefixe>_<numero>` (4 chiffres avec zéros).

| Préfixe | Catégorie |
|---|---|
| `pt` | présence table |
| `rem` | remplissage obligatoire |
| `uc` | unicité |
| `fk` | clé étrangère |
| `lv` | liste de valeurs |
| `rc` | remplissage conditionnel |
| `topo` | topologie / géométrie |
| `m` | règle métier |

Exemples : `ctrl_uc_0001`, `ctrl_lv_0042`, `ctrl_topo_017`.

## Contrôles spécifiques

### Principe

Un fichier SQL par règle. Chaque modèle appelle la macro `ctrl_specifique` qui génère le schéma de sortie unifié. Pas de placeholder `WHERE false` : si la table source est absente la requête échoue (le contrôle doit être retiré de `grace_ctrl_models`).

### Macro `ctrl_specifique`

Définie dans `macros/controls/ctrl_specifique.sql`. Paramètres :

| Paramètre | Obligatoire | Description |
|---|---|---|
| `id_test` | oui | Identifiant du test, ex. `ctrl_rc_0001` |
| `type_controle` | oui | Catégorie : `remplissage_conditionnel`, `topologie`, `regle_metier`… |
| `classe` | oui | Table GRACE THD principale (valeur de la colonne `classe` en sortie) |
| `cle_primaire` | oui | Colonne PK de l'alias `src` utilisée comme `id_entite` |
| `attribut` | oui | Attribut contrôlé |
| `description` | oui | Libellé du contrôle |
| `requ_princ` | oui | SQL complet du sous-SELECT aliasé `src` (table simple ou jointure) |
| `condition` | oui | Clause WHERE appliquée sur `src` (préfixer les colonnes par `src.`) |
| `detail_erreur` | non | Expression SQL pour `detail_erreur` ; défaut : `NULL::text` |
| `is_active` | non | Booléen pour activation dynamique (défaut: `true`). Pour les RC, calculé via `conteneurs[container_level] == 'C'` |

Exemple d'appel — cas simple (table unique) :

```jinja
{{ ctrl_specifique(
    id_test       = 'ctrl_rc_0001',
    type_controle = 'remplissage_conditionnel',
    classe        = 't_cable',
    cle_primaire  = 'cb_code',
    attribut      = 'cb_r3_code',
    description   = "Le champ [cb_r3_code] est vide alors que le câble est limité à la distribution",
    requ_princ    = "SELECT cb_code, cb_r3_code, cb_typelog FROM " ~ source('gracethd', 't_cable'),
    condition     = "src.cb_r3_code IS NULL AND src.cb_typelog = 'DI'"
) }}
```

Exemple d'appel — cas avec jointure :

```jinja
{{ ctrl_specifique(
    id_test       = 'ctrl_rc_0002',
    type_controle = 'remplissage_conditionnel',
    classe        = 't_cheminement',
    cle_primaire  = 'cm_code',
    attribut      = 'cm_compo',
    description   = "Le champ [cm_compo] est vide alors que le tronçon est de type GC à construire",
    requ_princ    = "SELECT cm_code, cm_compo, cm_avct, or_nom FROM "
                    ~ source('gracethd', 't_cheminement')
                    ~ " LEFT JOIN " ~ source('gracethd', 't_organisme')
                    ~ " ON cm_prop = or_code",
    condition     = "src.cm_compo IS NULL AND (src.cm_avct = 'C' OR src.or_nom = 'ORANGE')",
    detail_erreur = "'cm_avct = ' || src.cm_avct || ' / or_nom = ' || src.or_nom"
) }}
```

### Convention de nommage des fichiers

Format : `<prefixe>_<digit>_<table>_<attribut>[_<description-courte>].sql`

Le `<digit>` est un numéro séquentiel sur 4 chiffres, indépendant du numérotage legacy.

| Préfixe | Catégorie | `type_controle` |
|---|---|---|
| `rc` | Remplissage conditionnel | `remplissage_conditionnel` |
| `topo` | Topologie / géométrie | `topologie` |
| `m` | Règle métier | `regle_metier` |

Exemples :
- `rc_0001_t_cable_cb_r3_code.sql`
- `m_0001_t_site_st_typelog_coherence_local.sql`
- `topo_0001_t_cable_geom_continuite.sql`

Le suffixe `<description-courte>` est optionnel pour les cas simples (classe + attribut suffisent) et recommandé quand plusieurs contrôles portent sur le même attribut ou quand la condition mérite d'être explicitée dans le nom.

### Un `schema.yml` par modèle

Chaque fichier `.sql` est accompagné d'un `.yml` de même nom portant la description détaillée du contrôle. C'est le seul endroit où documenter la logique métier du contrôle.

### Activation

Pour les contrôles spécifiques **remplissage conditionnel** (`ctrl_rc_*`):
- **Paramétrés dans `param_ctrl_remplissage.csv`** avec colonnes `conteneur_c1..c4` (valeurs `O`/`C`/`N`) et `actif` (booléen)
- Chaque fichier `rc_*.sql` déclare :
  ```jinja
  {%- set container_level = var('grace_container_level', 'C3') -%}
  {%- set conteneurs = {'C1': 'N', 'C2': 'N', 'C3': 'C', 'C4': 'N'} -%}
  ```
- Activation dynamique via : `is_active = conteneurs[container_level] == 'C'` passé à `ctrl_specifique`
- Le contrôle est actif si **`actif = true` ET `conteneur_cX = 'C'`** où X = `grace_container_level`

Pour les autres contrôles spécifiques (topologie, métier) : l'activation se fait en incluant ou non le modèle dans `grace_ctrl_models` (package) ou `grace_ctrl_models_ext` (projet utilisateur).

## Consolidation : `rapport_controles.sql`

Matérialisé en `table`. Assemble tous les contrôles via deux variables dbt :

```yaml
# dbt_project.yml du package
vars:
  grace_ctrl_models:          # modèles du package, à maintenir ici
    - ctrl_fk
    - ctrl_liste_valeur
    - ctrl_presence_table
    - ctrl_remplissage
    - ctrl_unicite
  grace_ctrl_models_ext: []   # extensions utilisateur, vide par défaut
```

Le modèle concatène les deux listes et génère des commentaires `-- depends_on` pour que dbt résout les dépendances (nécessaire car `ref()` est dans une boucle dynamique) :

```jinja
{%- set ctrl_models = var('grace_ctrl_models', []) + var('grace_ctrl_models_ext', []) -%}

{% for m in ctrl_models %}
-- depends_on: {{ ref(m) }}
{% endfor %}

...

{% for m in ctrl_models %}
union all
select * from {{ ref(m) }}
{% endfor %}
```

### Ajouter un contrôle (package)

1. Créer `models/controls/generique/ctrl_xxx.sql` ou `specifique/.../ctrl_xxx.sql` avec `tags=['control']`
2. Ajouter `- ctrl_xxx` dans `grace_ctrl_models` du `dbt_project.yml`

### Ajouter un contrôle (projet utilisateur)

Dans le `dbt_project.yml` du projet consommateur :

```yaml
vars:
  grace_ctrl_models_ext:
    - ctrl_mon_controle
    - ctrl_autre_controle
```

Aucune modification des fichiers du package.

## Géolocalisation : `rapport_controles_geo.sql`

Modèle séparé qui enrichit `rapport_controles` d'une colonne `geom` résolue à partir de (`classe`, `id_entite`). Les contrôles eux-mêmes ne portent pas de géométrie : cette séparation évite d'embarquer une jointure d'héritage dans chaque contrôle.

Stratégie : un `UNION ALL` dispatché par `classe`, chaque branche utilisant la jointure adaptée :
- **Spatiale directe** : `LEFT JOIN` sur la table source via sa clé primaire.
- **Héritage noeud partagé** (`t_baie`, `t_ebp`…) : `LEFT JOIN t_noeud ON nd_code = id_entite`.
- **Héritage noeud via FK** (`t_ptech`, `t_site`) : jointure double, source puis `t_noeud`.
- **Fallback** : `geom = NULL` pour les classes non mappées.
