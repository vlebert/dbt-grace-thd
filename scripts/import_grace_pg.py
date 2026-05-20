#!/usr/bin/env python3
"""
Import GRACE THD data (shapefiles/GPKG + CSV) into PostgreSQL/PostGIS.

Reads connection details from dbt profiles, using the project name from
dbt_project.yml and the target name given on the command line.

Usage:
  python import_grace_pg.py [src_path] [dbt_target]
  python import_grace_pg.py ./NA-16025-BGNR dev
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("PyYAML required: pip install pyyaml")


# ---------------------------------------------------------------------------
# YAML helpers
# ---------------------------------------------------------------------------


def load_yaml(path: str) -> dict:
    with open(path) as f:
        return yaml.safe_load(f)


def dbt_project_root() -> Path:
    """Locate dbt_project.yml by walking up from the current directory."""
    here = Path.cwd()
    for d in [here, *here.parents]:
        if (d / "dbt_project.yml").exists():
            return d
    sys.exit("dbt_project.yml not found (looked upward from current dir)")


def read_project_config(project_root: Path):
    """Return (project_name, profile_name) from dbt_project.yml."""
    cfg = load_yaml(str(project_root / "dbt_project.yml"))
    name = cfg.get("name")
    profile = cfg.get("profile")
    if not name or not profile:
        sys.exit("dbt_project.yml: missing 'name' or 'profile' key")
    return name, profile


def read_db_creds(profile_name: str, target_name: str):
    """Parse ~/.dbt/profiles.yml and return {host,port,user,password,dbname,schema}."""
    path = Path.home() / ".dbt" / "profiles.yml"
    if not path.exists():
        sys.exit(f"Not found: {path}")

    cfg = load_yaml(str(path))
    profile = cfg.get(profile_name)
    if not profile:
        sys.exit(f"Profile '{profile_name}' not found in {path}")

    outputs = profile.get("outputs", {})
    target = outputs.get(target_name)
    if not target:
        sys.exit(f"Target '{target_name}' not found under profile '{profile_name}'")

    required = ["host", "port", "user", "pass", "dbname", "schema"]
    creds = {}
    for k in required:
        creds[k] = target.get(k)
        if creds[k] is None:
            sys.exit(f"Key '{k}' missing in target '{target_name}'")
    return {
        "db_host": str(creds["host"]),
        "db_port": str(creds["port"]),
        "db_user": str(creds["user"]),
        "db_password": str(creds["pass"]),
        "db_name": str(creds["dbname"]),
        "db_schema": str(creds["schema"]),
    }


# ---------------------------------------------------------------------------
# Import logic
# ---------------------------------------------------------------------------

SHP_TABLES = [
    "t_adresse",
    "t_cableline",
    "t_cheminement",
    "t_noeud",
    "t_point_leve",
    "t_pointaccueil",
    "t_tranchee",
    "t_zdep",
    "t_znro",
    "t_zsro",
]

CSV_TABLES = [
    "t_baie",
    "t_cab_chem",
    "t_cable",
    "t_cassette",
    "t_ebp",
    "t_fibre",
    "t_local",
    "t_love",
    "t_organisme",
    "t_position",
    "t_ptech",
    "t_reference",
    "t_site",
    "t_tiroir",
]

ALL_TABLES = SHP_TABLES + CSV_TABLES


def run(cmd, **kwargs):
    print("  \033[36m%s\033[0m" % " ".join(cmd), flush=True)
    subprocess.run(cmd, check=True, **kwargs)


def shell(cmd):
    """Like run but via shell (needed for psql pipes)."""
    print("  \033[36m%s\033[0m" % cmd, flush=True)
    subprocess.run(cmd, shell=True, check=True)


def import_data(creds: dict, src: str, script_dir: Path):
    db = creds
    schema = "gracethd_source"

    dest_db = (
        f"PG:dbname={db['db_name']} user={db['db_user']} "
        f"password={db['db_password']} host={db['db_host']} "
        f"port={db['db_port']} sslmode=disable "
        f"active_schema={schema}"
    )

    # --- Create schema -------------------------------------------------
    print(f"Creating schema {schema} if absent")
    shell(
        f'PGPASSWORD="{db["db_password"]}" psql '
        f"-h {db['db_host']} -p {db['db_port']} -U {db['db_user']} "
        f"-d {db['db_name']} -v ON_ERROR_STOP=1 "
        f'-c "CREATE SCHEMA IF NOT EXISTS {schema};"'
    )

    # --- Import --------------------------------------------------------
    base_ogr = [
        "ogr2ogr",
        "-f",
        "PostgreSQL",
        dest_db,
        "-lco",
        "GEOMETRY_NAME=geom",
        "-lco",
        "FID=ogc_fid",
        "-lco",
        "PRECISION=NO",
        "-nlt",
        "PROMOTE_TO_MULTI",
        "--config",
        "PG_USE_COPY",
        "YES",
        "-overwrite",
        "-progress",
    ]

    src_path = Path(src)
    if src_path.is_file() and src_path.suffix == ".gpkg":
        for table in ALL_TABLES:
            print(f"Import GPKG layer → {schema}.{table}")
            cmd = base_ogr + [
                "-nln",
                table,
                "-sql",
                f'SELECT * FROM "{table}"',
                str(src_path),
            ]
            run(cmd)
    else:
        # Shapefiles
        for table in SHP_TABLES:
            shp = src_path / f"{table}.shp"
            if not shp.exists():
                print(f"  missing, skip: {shp}")
                continue
            print(f"Import shapefile → {schema}.{table}")
            cmd = base_ogr + ["-nln", table, str(shp)]
            run(cmd)

        # CSV
        for table in CSV_TABLES:
            csv = src_path / f"{table}.csv"
            if not csv.exists():
                print(f"  missing, skip: {csv}")
                continue
            print(f"Import CSV → {schema}.{table}")
            cmd = [
                "ogr2ogr",
                "-f",
                "PostgreSQL",
                dest_db,
                "-nln",
                table,
                "-oo",
                "AUTODETECT_TYPE=YES",
                "-oo",
                "EMPTY_STRING_AS_NULL=YES",
                "--config",
                "PG_USE_COPY",
                "YES",
                "-overwrite",
                "-progress",
                str(csv),
            ]
            run(cmd)

    # --- Indexes -------------------------------------------------------
    index_sql = script_dir / "gracethd_indexes.sql"
    if index_sql.exists():
        print("Creating indexes")
        shell(
            f'PGPASSWORD="{db["db_password"]}" psql '
            f"-h {db['db_host']} -p {db['db_port']} -U {db['db_user']} "
            f"-d {db['db_name']} -v ON_ERROR_STOP=0 "
            f'-f "{index_sql}" 2>&1 | grep -v "does not exist" || true'
        )

    print("Import complete.")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser(
        description="Import GRACE THD data into PostgreSQL using dbt profile credentials"
    )
    parser.add_argument(
        "src",
        help="Source GPKG file or directory of shapefiles/CSVs",
    )
    parser.add_argument(
        "target",
        nargs="?",
        default=None,
        help="dbt target name in profiles.yml (default: the 'target' key in profiles.yml)",
    )
    args = parser.parse_args()

    # Resolve paths
    project_root = dbt_project_root()
    script_dir = Path(__file__).resolve().parent  # indexes are next to this script

    src = args.src
    if not os.path.exists(src):
        sys.exit(f"Source not found: {src}")

    # Project info
    project_name, profile_name = read_project_config(project_root)
    print(f"Project: {project_name} | Profile: {profile_name}")

    # If target not provided, read default from profiles.yml
    if args.target:
        target = args.target
    else:
        cfg = load_yaml(str(Path.home() / ".dbt" / "profiles.yml"))
        target = cfg.get(profile_name, {}).get("target", "dev")
    print(f"Target : {target}")

    creds = read_db_creds(profile_name, target)
    import_data(creds, src, script_dir)


if __name__ == "__main__":
    main()
