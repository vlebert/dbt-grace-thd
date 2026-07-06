# Image de démonstration : dbt-postgres + GDAL (ogr2ogr) + client psql.
# GDAL et psql sont requis par scripts/import_grace_pg.py pour charger
# les shapefiles/CSV dans PostGIS.
FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        gdal-bin \
        postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Dépendances Python alignées sur pyproject.toml (+ pyyaml pour le script d'import).
RUN pip install --no-cache-dir \
        "dbt-postgres>=1.10.0" \
        openpyxl \
        pyyaml

# Profil dbt vers le service PostGIS `db` (emplacement par défaut lu par dbt et par le script).
COPY docker/profiles.yml /root/.dbt/profiles.yml

WORKDIR /app
COPY . /app

ENTRYPOINT ["/app/docker/entrypoint.sh"]
