"""
Convertit les fichiers SQL GRACE THD (CREATE TABLE + INSERT) en seeds CSV dbt.
Ne traite que les tables l_* (listes de valeurs).

Usage :
    python scripts/sql_listes_to_seeds.py

Lit les 3 fichiers SQL depuis le chemin configuré dans SQL_FILES et écrit
les seeds dans seeds/listes/.
"""

import csv
import os
import re

SQL_FILES = [
    "/Users/vlebert/Library/CloudStorage/Dropbox/valerian/w/prod/GRACE_THD"
    "/pfthd-recommandations-gracethd-v1.1.0/An. 2C - code informatique"
    "/1_Referentiel_Commun.sql",
    "/Users/vlebert/Library/CloudStorage/Dropbox/valerian/w/prod/GRACE_THD"
    "/pfthd-recommandations-gracethd-v1.1.0/An. 2C - code informatique"
    "/2_Referentiel_Reseau_Optique.sql",
    "/Users/vlebert/Library/CloudStorage/Dropbox/valerian/w/prod/GRACE_THD"
    "/pfthd-recommandations-gracethd-v1.1.0/An. 2C - code informatique"
    "/3_Referentiel_Genie_Civil.sql",
]

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "seeds", "listes")


def parse_pg_string(s):
    """Retire les guillemets simples et dé-escape '' → '."""
    s = s.strip()
    if s.startswith("'") and s.endswith("'"):
        s = s[1:-1]
    return s.replace("''", "'")


def parse_values_list(values_str):
    """
    Parse une liste de valeurs SQL du type ('a','b','c').
    Gère les chaînes avec '' (apostrophe escapée) et les espaces.
    Retourne une liste de strings dé-escapées.
    """
    values_str = values_str.strip()
    if values_str.startswith("(") and values_str.endswith(")"):
        values_str = values_str[1:-1]

    tokens = []
    current = ""
    in_string = False

    i = 0
    while i < len(values_str):
        c = values_str[i]
        if c == "'" and not in_string:
            in_string = True
            current += c
        elif c == "'" and in_string:
            # Peek next char
            if i + 1 < len(values_str) and values_str[i + 1] == "'":
                current += "''"
                i += 1
            else:
                in_string = False
                current += c
        elif c == "," and not in_string:
            tokens.append(parse_pg_string(current.strip()))
            current = ""
        else:
            current += c
        i += 1

    if current.strip():
        tokens.append(parse_pg_string(current.strip()))

    return tokens


def extract_columns(sql, table_name):
    """Extrait les noms de colonnes depuis le CREATE TABLE d'une table l_*."""
    pattern = (
        rf"CREATE TABLE \S+\.{re.escape(table_name)}\s*\((.*?)\);"
    )
    match = re.search(pattern, sql, re.DOTALL | re.IGNORECASE)
    if not match:
        return None

    body = match.group(1)
    cols = []
    for line in body.splitlines():
        line = line.strip()
        # Ignorer les contraintes et lignes vides
        if not line or line.upper().startswith("CONSTRAINT"):
            continue
        col_name = line.split()[0]
        cols.append(col_name)
    return cols


def extract_inserts(sql, table_name):
    """
    Extrait toutes les lignes VALUES pour une table donnée.
    Les INSERT sont sur 2 lignes : INSERT INTO schema.table\n\tVALUES (...);
    """
    pattern = (
        rf"INSERT INTO \S+\.{re.escape(table_name)}\s*\n\s*VALUES\s*(\(.*?\));"
    )
    matches = re.findall(pattern, sql, re.DOTALL | re.IGNORECASE)
    return [parse_values_list(m) for m in matches]


def process_files(sql_files, output_dir):
    os.makedirs(output_dir, exist_ok=True)

    # Agrège le SQL de tous les fichiers (certaines tables l_* apparaissent
    # dans plusieurs fichiers avec des valeurs différentes)
    all_sql_by_file = []
    for path in sql_files:
        with open(path, encoding="utf-8") as f:
            all_sql_by_file.append(f.read())

    # Collecte toutes les tables l_* trouvées
    table_pattern = re.compile(
        r"CREATE TABLE \S+\.(l_[a-z_]+)\s*\(", re.IGNORECASE
    )
    tables_seen = {}  # table_name → (columns, rows)

    for sql in all_sql_by_file:
        for match in table_pattern.finditer(sql):
            table_name = match.group(1)
            if table_name not in tables_seen:
                cols = extract_columns(sql, table_name)
                if cols:
                    tables_seen[table_name] = (cols, [])

        for table_name, (cols, rows) in tables_seen.items():
            new_rows = extract_inserts(sql, table_name)
            rows.extend(new_rows)

    # Écriture des CSV
    written = []
    for table_name, (cols, rows) in sorted(tables_seen.items()):
        if not rows:
            print(f"  [SKIP] {table_name} — aucun INSERT trouvé")
            continue

        out_path = os.path.join(output_dir, f"{table_name}.csv")
        with open(out_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(cols)
            for row in rows:
                # Pad ou tronque pour correspondre au nombre de colonnes
                padded = row[: len(cols)] + [""] * max(0, len(cols) - len(row))
                writer.writerow(padded)

        written.append(table_name)
        print(f"  [OK]   {table_name} — {len(rows)} lignes → seeds/listes/{table_name}.csv")

    print(f"\n{len(written)} seeds générés dans {output_dir}")


if __name__ == "__main__":
    process_files(SQL_FILES, OUTPUT_DIR)
