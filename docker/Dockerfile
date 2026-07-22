# Image de démonstration : dbt-postgres + GDAL (ogr2ogr) + client psql.
# GDAL et psql sont requis par scripts/import_grace_pg.py pour charger
# les shapefiles/CSV dans PostGIS.
#
# Les dépendances Python sont installées avec uv depuis uv.lock
# (installation reproductible, alignée sur le mode standalone).
FROM ghcr.io/astral-sh/uv:python3.11-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        gdal-bin \
        postgresql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

# 1) Dépendances seules (couche cachée tant que le lock ne change pas).
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-install-project

# 2) Le reste du projet (le .venv construit ci-dessus est préservé via .dockerignore).
COPY . /app

# Les exécutables du venv (dbt, python…) passent en tête de PATH pour l'entrypoint.
ENV PATH="/app/.venv/bin:$PATH"

# Profil dbt vers le service PostGIS `db` (emplacement par défaut lu par dbt et par le script).
COPY docker/profiles.yml /root/.dbt/profiles.yml

ENTRYPOINT ["/app/docker/entrypoint.sh"]
