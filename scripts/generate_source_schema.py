#!/usr/bin/env python3
"""Génère scripts/gracethd_source_schema.sql depuis le seed param_ctrl_remplissage.csv.

Le seed `seeds/controls/param_ctrl_remplissage.csv` est la source de vérité de la
liste (table, attribut) attendue par le modèle GRACE THD. On en dérive le schéma
des tables sources `gracethd_source` :

  - toutes les colonnes en `text` (import "sans altération" : la donnée brute est
    chargée telle quelle, le typage/validation se fait en aval dans la couche `base`
    via pg_input_is_valid, de façon non bloquante) ;
  - la colonne `geom` en `geometry` (générique, sans contrainte de SRID) ;
  - aucune contrainte (PK / NOT NULL / FK) : les doublons, nuls et clés invalides
    doivent pouvoir être chargés puis signalés par les contrôles.

Pré-créer ces tables AVANT l'import permet à `ogr2ogr -append` de ne remplir que les
colonnes présentes dans le jeu de données : les colonnes absentes restent NULL et
sont correctement remontées comme non renseignées par les contrôles de remplissage
(au lieu de faire échouer les modèles sur "column does not exist").

Le SRID de la colonne `geom` provient de la variable projet `grace_srid`
(`dbt_project.yml`) — source de vérité unique, partagée avec le typage geom des
modèles base/elem. Il peut être surchargé ponctuellement via l'option `--srid`.

Usage :
  python scripts/generate_source_schema.py            # SRID = vars.grace_srid
  python scripts/generate_source_schema.py --srid 4326
"""

import argparse
import csv
import sys
from pathlib import Path

SCHEMA = "gracethd_source"
GEOM_COLUMN = "geom"
FALLBACK_SRID = 2154  # RGF93 / Lambert-93, si vars.grace_srid absent


def project_root() -> Path:
    """Racine du projet dbt (remonte depuis ce script)."""
    here = Path(__file__).resolve().parent
    for d in [here, *here.parents]:
        if (d / "dbt_project.yml").exists():
            return d
    sys.exit("dbt_project.yml introuvable")


def read_project_srid(root: Path) -> int:
    """Lit vars.grace_srid dans dbt_project.yml (source de vérité), sinon FALLBACK_SRID."""
    try:
        import yaml
    except ImportError:
        return FALLBACK_SRID
    with open(root / "dbt_project.yml", encoding="utf-8") as f:
        cfg = yaml.safe_load(f) or {}
    return int((cfg.get("vars") or {}).get("grace_srid", FALLBACK_SRID))


def read_tables(seed_path: Path) -> dict:
    """Retourne {table: [colonnes...]} en préservant l'ordre du seed."""
    tables: dict[str, list[str]] = {}
    with open(seed_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            classe = (row.get("classe") or "").strip()
            attribut = (row.get("attribut") or "").strip()
            if not classe or not attribut:
                continue
            cols = tables.setdefault(classe, [])
            if attribut not in cols:
                cols.append(attribut)
    return tables


def render_sql(tables: dict, srid: int) -> str:
    lines = [
        "-- Schéma des tables sources GRACE THD (gracethd_source).",
        "-- Fichier GÉNÉRÉ par scripts/generate_source_schema.py à partir du seed",
        "-- seeds/controls/param_ctrl_remplissage.csv — NE PAS éditer à la main.",
        "--",
        "-- Toutes les colonnes sont en `text` (import brut non bloquant) ; `geom` est",
        f"-- contrainte au SRID {srid}. Aucune contrainte de clé/nullité, pour ne jamais",
        "-- bloquer l'import (utilisez le même SRID à l'import via GRACE_SRID).",
        "",
        f"CREATE SCHEMA IF NOT EXISTS {SCHEMA};",
        "",
    ]
    for table in sorted(tables):
        cols = tables[table]
        lines.append(f"DROP TABLE IF EXISTS {SCHEMA}.{table};")
        lines.append(f"CREATE TABLE {SCHEMA}.{table} (")
        col_defs = []
        for col in cols:
            if col.lower() == GEOM_COLUMN:
                col_defs.append(f"    {col} geometry(Geometry, {srid})")
            else:
                col_defs.append(f"    {col} text")
        lines.append(",\n".join(col_defs))
        lines.append(");")
        lines.append("")
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(
        description="Génère gracethd_source_schema.sql depuis param_ctrl_remplissage.csv"
    )
    parser.add_argument(
        "--srid",
        type=int,
        default=None,
        help="SRID de la colonne geom (défaut : vars.grace_srid de dbt_project.yml)",
    )
    args = parser.parse_args()

    root = project_root()
    srid = args.srid if args.srid is not None else read_project_srid(root)
    seed_path = root / "seeds" / "controls" / "param_ctrl_remplissage.csv"
    if not seed_path.exists():
        sys.exit(f"Seed introuvable : {seed_path}")

    tables = read_tables(seed_path)
    sql = render_sql(tables, srid)

    out_path = root / "scripts" / "gracethd_source_schema.sql"
    out_path.write_text(sql, encoding="utf-8")

    n_geom = sum(
        1 for cols in tables.values() if any(c.lower() == GEOM_COLUMN for c in cols)
    )
    print(f"Écrit : {out_path} (SRID {srid})")
    print(f"  {len(tables)} tables ({n_geom} géométriques)")


if __name__ == "__main__":
    main()
