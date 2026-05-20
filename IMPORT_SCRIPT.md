# Import des données - Package DBT pour GRACE THD

**Script d'import des données sources vers PostgreSQL/PostGIS**

> **Pour une présentation générale** : [Retour au README](README.md)

---


## Prérequis

- Python 3 installé
- `ogr2ogr` (GDAL) et `psql` (PostgreSQL) disponibles dans le terminal
- Un fichier `~/.dbt/profiles.yml` correctement configuré
- Extension PostGIS activée sur votre base de données
- 
---

## Utilisation

```bash
# Depuis la racine de votre projet DBT
python dbt_packages/grace_thd/scripts/import_grace_pg.py CHEMIN_SOURCE [CIBLE_DBT]
```

**Arguments :**

| Argument | Obligatoire | Description |
|----------|-------------|-------------|
| `CHEMIN_SOURCE` | oui | Dossier de shapefiles/CSV ou fichier `.gpkg` |
| `CIBLE_DBT` | non | Nom de la cible dans `profiles.yml` (défaut : la cible par défaut du profil) |

---

## Exemples

```bash
# Importer un GeoPackage vers la base de dev
python scripts/import_grace_pg.py /chemin/donnees.gpkg

# Importer un dossier vers la base de production
python scripts/import_grace_pg.py ./NA-16025-BGNR prod
```

---

## Fonctionnement

1. Le script lit `dbt_project.yml` pour connaître le nom du profil dbt (`grace_thd`)
2. Il lit `~/.dbt/profiles.yml` pour récupérer les identifiants de connexion (hôte, base, schéma, etc.)
3. Il crée le schéma cible s'il n'existe pas
4. Il importe les tables (géométriques et attributaires)
5. Il crée les index pour optimiser les requêtes

## Formats acceptés

- **GeoPackage** (`.gpkg`) : toutes les couches sont importées automatiquement
- **Dossier** : les shapefiles (`.shp`) et CSV (`.csv`) sont importés table par table
