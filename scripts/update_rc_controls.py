#!/usr/bin/env python3
"""
Script pour automatiser la mise à jour des contrôles RC :
1. Ajoute les lignes RC au seed param_ctrl_remplissage.csv avec conteneur_c3='C' par défaut
2. Modifie chaque fichier rc_*.sql pour ajouter :
   - Les variables container_level et conteneurs
   - Le paramètre is_active dans l'appel à ctrl_specifique
"""

import csv
import re
from pathlib import Path

# Chemins
SEED_PATH = Path("seeds/controls/param_ctrl_remplissage.csv")
RC_DIR = Path("models/controls/specifique/remplissage_cond")

# Lire le seed existant
with open(SEED_PATH, "r") as f:
    reader = csv.DictReader(f)
    seed_data = list(reader)

# Extraire les id_test existants
seed_ids = {row["id_test"] for row in seed_data}

# Parser tous les fichiers rc_*.sql
rc_files = list(RC_DIR.rglob("rc_*.sql"))

for filepath in rc_files:
    with open(filepath, "r") as f:
        content = f.read()

    # Extraire l'id_test
    match = re.search(
        r"ctrl_specifique\s*\(\s*id_test\s*=\s*\'([^\']+)\'(,|\s)", content
    )
    if not match:
        print(f"Warning: Could not find id_test in {filepath}")
        continue

    id_test = match.group(1)

    # Ajouter au seed si pas déjà présent avec conteneur_c3='C' par défaut
    if id_test not in seed_ids:
        # Extraire classe, attribut, cle_primaire
        classe_match = re.search(r"classe\s*=\s*\'([^\']+)\'(,|\s)", content)
        attribut_match = re.search(r"attribut\s*=\s*\'([^\']+)\'(,|\s)", content)
        cle_primaire_match = re.search(
            r"cle_primaire\s*=\s*\'([^\']+)\'(,|\s)", content
        )

        classe = classe_match.group(1) if classe_match else ""
        attribut = attribut_match.group(1) if attribut_match else ""
        cle_primaire = cle_primaire_match.group(1) if cle_primaire_match else ""

        seed_data.append(
            {
                "id_test": id_test,
                "classe": classe,
                "attribut": attribut,
                "cle_primaire": cle_primaire,
                "conteneur_c1": "N",
                "conteneur_c2": "N",
                "conteneur_c3": "C",
                "conteneur_c4": "N",
                "actif": "true",
            }
        )
        seed_ids.add(id_test)

# Écrire le seed mis à jour
with open(SEED_PATH, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=seed_data[0].keys())
    writer.writeheader()
    writer.writerows(seed_data)

print(f"✅ Seed mis à jour: {len(seed_data)} lignes au total")

# Maintenant modifier chaque fichier rc_*.sql
for filepath in rc_files:
    with open(filepath, "r") as f:
        lines = f.readlines()

    # Extraire l'id_test
    content = "".join(lines)
    match = re.search(
        r"ctrl_specifique\s*\(\s*id_test\s*=\s*\'([^\']+)\'(,|\s)", content
    )
    if not match:
        print(f"Warning: Could not find id_test in {filepath}")
        continue

    id_test = match.group(1)

    # Trouver la ligne du seed pour ce id_test
    rc_seed_row = next((row for row in seed_data if row["id_test"] == id_test), None)
    if not rc_seed_row:
        print(f"Warning: {id_test} not found in seed!")
        continue

    conteneurs = {
        "C1": rc_seed_row["conteneur_c1"],
        "C2": rc_seed_row["conteneur_c2"],
        "C3": rc_seed_row["conteneur_c3"],
        "C4": rc_seed_row["conteneur_c4"],
    }

    # Créer les nouvelles lignes à insérer après config
    conteneurs_decl = f"{{'C1': '{conteneurs['C1']}', 'C2': '{conteneurs['C2']}', 'C3': '{conteneurs['C3']}', 'C4': '{conteneurs['C4']}'}}"
    new_lines = [
        "\n",
        "{%- set container_level = var('grace_container_level', 'C3') -%}\n",
        f"{{%- set conteneurs = {conteneurs_decl} -%}}\n",
    ]

    # Trouver la ligne config et insérer après
    insert_idx = None
    for i, line in enumerate(lines):
        if "{{ config(materialized=" in line and "tags=['grace_control']" in line:
            insert_idx = i + 1
            break

    if insert_idx is None:
        print(f"Warning: Could not find config line in {filepath}")
        continue

    lines[insert_idx:insert_idx] = new_lines

    # Trouver la parenthèse fermante de ctrl_specifique et ajouter is_active
    close_paren_idx = None
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped == ")" or stripped.endswith(")"):
            # Vérifier que c'est dans le contexte de ctrl_specifique
            if i > 0 and "ctrl_specifique" in "".join(lines[max(0, i - 10) : i]):
                close_paren_idx = i
                break

    if close_paren_idx is None:
        print(f"Warning: Could not find closing parenthesis for {filepath}")
        continue

    # Remplacer la ligne avec ) par le paramètre is_active (avec virgule avant)
    indent = re.match(r"^\s*", lines[close_paren_idx]).group(0)
    # Ajouter une virgule à la fin de la ligne précédente si ce n'est pas déjà fait
    if close_paren_idx > 0:
        prev_line = lines[close_paren_idx - 1].rstrip()
        if not prev_line.endswith(","):
            lines[close_paren_idx - 1] = prev_line + ",\n"
    lines[close_paren_idx] = (
        f"{indent}    is_active      = conteneurs[container_level] == 'C'\n{indent})\n"
    )

    # Écrire le fichier modifié
    with open(filepath, "w") as f:
        f.writelines(lines)

    print(f"  → Modified: {filepath.relative_to(Path('models'))}")

print("\n✅ Tous les fichiers RC ont été mis à jour!")
