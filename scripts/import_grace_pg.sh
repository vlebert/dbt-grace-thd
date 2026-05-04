#!/bin/bash
#
# Import d'un jeu de données GRACE THD (shapefiles + CSV) vers PostgreSQL/PostGIS.
# Cible : schéma `gracethd_source` (celui référencé par les sources dbt).
#
# Usage :
#   ./import_grace_pg.sh [chemin/vers/dossier_ou_fichier.gpkg]
# Par défaut : ./NA-16025-BGNR (relatif au script)

set -euo pipefail

# --- Credentials PG (à adapter / surcharger via env) -------------------------
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=postgres
export DB_USER=postgres
export DB_PASSWORD=password
export DB_SSLMODE=disable
export DB_SCHEMA=gracethd_source

# --- Source ------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${1:-$SCRIPT_DIR/NA-16025-BGNR}"

if [[ ! -f "$SRC" && ! -d "$SRC" ]]; then
  echo "Source introuvable : $SRC" >&2
  exit 1
fi

DEST_DB="PG:dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD host=$DB_HOST port=$DB_PORT sslmode=$DB_SSLMODE active_schema=$DB_SCHEMA"

# --- Tables à importer -------------------------------------------------------
# Shapefiles (tables géométriques)
SHP_TABLES=(
  "t_adresse"
  "t_cableline"
  "t_cheminement"
  "t_noeud"
  "t_point_leve"
  "t_pointaccueil"
  "t_tranchee"
  "t_zdep"
  "t_znro"
  "t_zsro"
)

# CSV (tables attributaires)
CSV_TABLES=(
  "t_baie"
  "t_cab_chem"
  "t_cable"
  "t_cassette"
  "t_ebp"
  "t_fibre"
  "t_local"
  "t_love"
  "t_organisme"
  "t_position"
  "t_ptech"
  "t_reference"
  "t_site"
  "t_tiroir"
)

ALL_TABLES=("${SHP_TABLES[@]}" "${CSV_TABLES[@]}")

# --- Pré-requis : créer le schéma cible --------------------------------------
echo "Création du schéma $DB_SCHEMA si absent"
PGPASSWORD="$DB_PASSWORD" psql \
  -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
  -v ON_ERROR_STOP=1 \
  -c "CREATE SCHEMA IF NOT EXISTS $DB_SCHEMA;"

# --- Import selon type de source -----------------------------------------------
if [[ -f "$SRC" && "$SRC" == *.gpkg ]]; then
  for TABLE in "${ALL_TABLES[@]}"; do
    echo "Import GPKG couche → $DB_SCHEMA.$TABLE"
    ogr2ogr -f "PostgreSQL" "$DEST_DB" "$SRC" \
      -nln "$TABLE" \
      -lco GEOMETRY_NAME=geom \
      -lco FID=ogc_fid \
      -lco PRECISION=NO \
      -nlt PROMOTE_TO_MULTI \
      --config PG_USE_COPY YES \
      -sql "SELECT * FROM \"$TABLE\"" \
      -overwrite -progress
  done
else
  # Import shapefiles
  for TABLE in "${SHP_TABLES[@]}"; do
    SHP="$SRC/$TABLE.shp"
    [[ ! -f "$SHP" ]] && echo "Shapefile manquant, ignoré : $SHP" && continue
    echo "Import shapefile → $DB_SCHEMA.$TABLE"
    ogr2ogr -f "PostgreSQL" "$DEST_DB" "$SHP" \
      -nln "$TABLE" \
      -lco GEOMETRY_NAME=geom \
      -lco FID=ogc_fid \
      -lco PRECISION=NO \
      -nlt PROMOTE_TO_MULTI \
      --config PG_USE_COPY YES \
      -overwrite -progress
  done

  # Import CSV
  for TABLE in "${CSV_TABLES[@]}"; do
    CSV="$SRC/$TABLE.csv"
    [[ ! -f "$CSV" ]] && echo "CSV manquant, ignoré : $CSV" && continue
    echo "Import CSV → $DB_SCHEMA.$TABLE"
    ogr2ogr -f "PostgreSQL" "$DEST_DB" "$CSV" \
      -nln "$TABLE" \
      -oo AUTODETECT_TYPE=YES \
      -oo EMPTY_STRING_AS_NULL=YES \
      --config PG_USE_COPY YES \
      -overwrite -progress
  done
fi

# --- Création des index ------------------------------------------------------
echo "Création des index sur $DB_SCHEMA"

PGPASSWORD="$DB_PASSWORD" psql \
  -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
  -v ON_ERROR_STOP=0 \
  -f "$SCRIPT_DIR/gracethd_indexes.sql" 2>&1 | grep -v "does not exist"

echo "Import terminé."
