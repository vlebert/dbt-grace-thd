"""
Génère seeds/controls/param_ctrl_liste_valeur.csv à partir des fichiers SQL GRACE THD.

Extrait toutes les contraintes FK de t_* vers l_* (listes de valeurs).
Pattern dans les SQL :
  ALTER TABLE schema.t_xxx ADD CONSTRAINT fk_yyy FOREIGN KEY (col)
  REFERENCES schema.l_zzz (code) MATCH SIMPLE

Usage :
    python3 scripts/generate_param_ctrl_liste_valeur.py
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

OUTPUT = os.path.join(
    os.path.dirname(__file__), "..", "seeds", "controls", "param_ctrl_liste_valeur.csv"
)

# Pattern FK vers l_* : 2 lignes consécutives
# Ligne 1 : ALTER TABLE schema.t_xxx ADD CONSTRAINT ... FOREIGN KEY (col)
# Ligne 2 : REFERENCES schema.l_yyy (code) ...
FK_PATTERN = re.compile(
    r"ALTER TABLE \S+\.(t_\w+)\s+ADD CONSTRAINT \S+ FOREIGN KEY \((\w+)\)\s*\n"
    r"\s*REFERENCES \S+\.(l_\w+) \(code\)",
    re.IGNORECASE,
)

# Pattern PK dans CREATE TABLE : CONSTRAINT xxx PRIMARY KEY (col)
PK_PATTERN = re.compile(
    r'CREATE TABLE \S+\.(t_\w+)\s*\(.*?CONSTRAINT\s+\S+\s+PRIMARY KEY\s*\((\w+)\)',
    re.DOTALL | re.IGNORECASE,
)


def extract_primary_keys(sql):
    """Retourne {table_name: pk_column}."""
    return {m.group(1): m.group(2) for m in PK_PATTERN.finditer(sql)}


def extract_fk_to_lists(sql):
    """Retourne liste de (classe, attribut, table_liste)."""
    return [
        (m.group(1), m.group(2), m.group(3))
        for m in FK_PATTERN.finditer(sql)
    ]


def main():
    all_pks = {}
    all_fks = []

    for path in SQL_FILES:
        with open(path, encoding="utf-8") as f:
            sql = f.read()
        all_pks.update(extract_primary_keys(sql))
        all_fks.extend(extract_fk_to_lists(sql))

    # Déduplique (même FK peut apparaître dans plusieurs fichiers)
    seen = set()
    rows = []
    counter = 1
    for classe, attribut, table_liste in sorted(all_fks):
        key = (classe, attribut, table_liste)
        if key in seen:
            continue
        seen.add(key)
        pk = all_pks.get(classe, f"{classe[2:]}_code")  # fallback convention
        rows.append({
            "id_test": f"ctrl_lv_{counter:04d}",
            "classe": classe,
            "attribut": attribut,
            "cle_primaire": pk,
            "table_liste": table_liste,
            "actif": "true",
        })
        counter += 1

    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    with open(OUTPUT, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f, fieldnames=["id_test", "classe", "attribut", "cle_primaire", "table_liste", "actif"]
        )
        writer.writeheader()
        writer.writerows(rows)

    print(f"{len(rows)} entrées générées → {OUTPUT}")
    for r in rows:
        print(f"  {r['id_test']}  {r['classe']}.{r['attribut']} → {r['table_liste']}")


if __name__ == "__main__":
    main()
