# Thématique « Capacité »

**Méthode de calcul de la capacité du réseau** (locaux desservis, fibres distribuées et raccordées) le long de la chaîne PBO → câble → SRO.

> Lecteur cible : connaît le modèle GRACE THD (locaux, PBO, câbles, fibres, routes optiques). Ce document décrit la **méthode de comptage**, pas le détail SQL.

---

## Vue d'ensemble

Tous les comptages reposent sur le modèle **`ropt_section`** (couche `ropt`), qui « déplie » chaque route optique en étapes ordonnées (`ropt_ordr`) du NRO/SRO jusqu'au local d'extrémité. Chaque étape porte l'élément traversé : local amont, point de branchement amont, position, câble, fibre.

Cinq modèles de comptage s'enchaînent, puis un modèle de restitution graphe (`cap_syno_json`) :

```
ropt_section ─┬─► cap_zpbo ──► cap_pbo ─┬─► cap_cb_pbo ──► cap_cb ─┐
              │                         │                          ├─► cap_syno_json
              └─────────────────────────┘   cap_pbo ───────────────┘
ropt_section ─────────────────────────────► cap_sro
```

| Modèle          | Grain                  | Répond à la question…                                  |
|-----------------|------------------------|--------------------------------------------------------|
| `cap_zpbo`      | 1 ligne / PBO          | Quels locaux ce PBO dessert-il ?                       |
| `cap_pbo`       | 1 ligne / PBO          | Combien de locaux / fibres ce PBO porte-t-il ?        |
| `cap_cb_pbo`    | 1 ligne / câble × PBO  | Que dessert ce câble de distribution, PBO par PBO ?   |
| `cap_cb`        | 1 ligne / câble DI     | Quelle est la charge totale d'un câble de distribution ? |
| `cap_sro`       | 1 ligne / SRO          | Combien de fibres de transport / câbles de distribution arrivent au SRO ? |
| `cap_syno_json` | 1 ligne / zone SRO     | À quoi ressemble le synoptique de distribution de la zone (graphe noeuds/arêtes) ? |

---

## 1. `cap_zpbo` — zone d'influence d'un PBO

Détermine, pour chaque PBO, l'**ensemble des locaux desservis**.

**Règle d'attribution (un local = un PBO) :**

1. **PBO de raccordement** s'il existe : c'est le point de branchement situé **juste en amont du local dans sa route optique** (l'étape qui précède le local dans `ropt_section`). Il reflète le raccordement *réel* sur le terrain.
2. **Sinon, PBO de pré-affectation** : la valeur `lc_bp_codf` portée par le local. C'est le rattachement *prévu* en étude, que le local soit déjà raccordé ou non.

Autrement dit : on privilégie toujours la réalité du réseau (raccordé) et on retombe sur la prévision (pré-affecté) à défaut. Un local n'est compté **qu'une seule fois**, sous son PBO de raccordement s'il existe, sinon sous son PBO de pré-affectation.

> **Point de méthode important** — Le PBO de raccordement se lit sur la route *complète*. Dans `ropt_section`, les étapes intermédiaires (PBO traversés) n'ont en général pas de local renseigné : seul le local d'extrémité l'est. Le calcul de l'« étape précédente » doit donc se faire sur l'intégralité de la route **avant** de rattacher les locaux, sinon le PBO de raccordement est perdu et tous les locaux basculeraient à tort sur leur pré-affectation.

**Sorties :**
- `bp_nb_loc` : nombre de locaux distincts desservis ;
- `lc_codes` : liste des codes locaux (séparés par des virgules) ;
- `geom` : **étoile** (MultiLineString) reliant le point du PBO à chacun de ses locaux. C'est un outil d'**audit visuel** : une branche anormalement longue trahit une pré-affectation ou un raccordement incohérent.

---

## 2. `cap_pbo` — capacité d'un PBO

Reprend toutes les colonnes du PBO (`elem_bp`, filtré sur `bp_typelog = 'PBO'`) et y ajoute :

- **`bp_nb_loc`** : nombre de locaux desservis, repris directement de `cap_zpbo`.
- **`bp_nb_fo_distrib`** : nombre de **fibres distribuées** par le PBO. Comptées sur les sections de route rattachées au PBO et retenues lorsque la position amont a une fonction de distribution/attente (`ps_fonct` ∈ {`AT`, `MA`}) **ou** que le câble traversé est de type raccordement (`cb_typelog = 'RA'`).
- **`bp_nb_fo_racco`** : sous-ensemble du précédent limité aux **fibres raccordées** (câble `RA` uniquement).
- **`zs_code`** : zone SRO amont. Déterminée via le local de **départ** de la route (étape `ropt_ordr = 0`), rapproché de `t_zsro`.

---

## 3. `cap_cb_pbo` — câble de distribution × PBO desservi

Détaille, pour chaque **câble de distribution** (`cb_typelog = 'DI'`), ce qu'il achemine **vers chaque PBO de destination**.

- **PBO de destination** : pour chaque route empruntée par une fibre du câble, c'est le **dernier PBO** de la route (le PBO le plus en aval, `ropt_ordr` le plus élevé). Un même câble peut donc avoir plusieurs PBO de destination.
- **`cb_nb_fo_distrib`** : nombre de fibres du câble qui aboutissent à ce PBO de destination.
- **`bp_nb_loc`, `bp_nb_fo_distrib`, `bp_nb_fo_racco`** : caractéristiques du PBO de destination, reprises de `cap_pbo`.
- **`zs_code`, `zs_refpm`** : zone SRO amont, via le local de départ de la route.

---

## 4. `cap_cb` — capacité totale d'un câble de distribution

Agrège `cap_cb_pbo` par câble (`cb_typelog = 'DI'`), pour donner la charge consolidée du câble :

- **`cb_nb_loc`** : total des locaux desservis par l'ensemble des PBO destinations du câble.
- **`cb_nb_fo_distrib`**, **`cb_nb_fo_racco`** : totaux de fibres distribuées / raccordées.
- **`destinations`** : liste des PBO desservis par le câble.
- **`zs_code`, `zs_refpm`** : zone SRO de rattachement.

---

## 5. `cap_sro` — desserte d'un SRO

Pour chaque local de type SRO (`lc_typelog = 'SRO'`), compte ce qui y arrive :

- **`nb_fo_transport`** : nombre de fibres de **transport** présentes au SRO (sections de route de type `TR` ou `CT`).
- **`nb_cb_distribution`** : nombre de **câbles de distribution distincts** (`DI`) partant du SRO.

Conserve la géométrie du local (`elem_lc_st_nd`).

---

## 6. `cap_syno_json` — synoptique de zone (graphe)

Modèle de **restitution** (et non de comptage) : reproduit le legacy `v_syno_cytoscape`. Il assemble, **pour chaque zone SRO (`zs_code`)**, le graphe de distribution au format Cytoscape.

À partir de chaque **câble de distribution** (`cap_cb`), on reconstitue une arête reliant ses deux extrémités :
- les **PBO** aux extrémités (`cb_bp1` / `cb_bp2`), enrichis de leur capacité via `cap_pbo` ;
- le **local technique / SRO**, atteint via les baies (`cb_ba1` / `cb_ba2` → `t_baie` → `t_local` → `t_site`).

**Sorties** (une ligne par zone) :
- **`json_data`** (JSONB) : le graphe complet au format Cytoscape `{"nodes": […], "edges": […]}`, directement passable à l'option `elements` de Cytoscape.
  - `nodes` : PBO et local technique, chacun `{"data": {"id", "label", "properties"}}`. Les noeuds partagés entre plusieurs câbles sont dédoublonnés **par identifiant** (`DISTINCT ON (id)`) — garantit des `id` uniques côté Cytoscape. Les propriétés portent codes, **étiquettes** (`*_etiquet`) et compteurs de capacité (locaux, fibres distribuées, raccordées).
  - `edges` : un câble = un lien orienté `source → target`.
- **`geom`** : polygone de la zone SRO (`t_zsro`).

> Les compteurs de capacité embarqués dans le JSON permettent un rendu **coloré par surcapacité** (fibres distribuées / locaux) côté client, sans requête supplémentaire.

---

## Conventions transverses

- **Comptage non bloquant** : un local sans PBO identifiable, un PBO sans géométrie ou une route incomplète n'interrompent pas le calcul ; ils sont simplement absents du résultat correspondant (cohérent avec la philosophie « intégration progressive » du package).
- **Clé primaire `id`** régénérée (`row_number()::int4`) sur chaque modèle matérialisé, pour la compatibilité QGIS.
- **Source unique de vérité** pour la traversée du réseau : `ropt_section`. Toute évolution de la logique de comptage doit y être rapportée.
