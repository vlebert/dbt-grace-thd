#!/usr/bin/env python3
"""Génère macros/controls/create_source_indexes.sql depuis scripts/gracethd_indexes.sql.

Le fichier .sql reste la source de vérité (utilisable directement via psql).
Ce script en extrait la liste des index (nom, table, colonnes, unique) et produit
une macro dbt data-driven, idempotente et non-bloquante :
  - vérifie l'existence de la table ET de chaque colonne avant tout CREATE ;
  - saute les index déjà présents ;
  - utilise CREATE INDEX IF NOT EXISTS.

Usage : python scripts/generate_index_macro.py
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "scripts" / "gracethd_indexes.sql"
DST = ROOT / "macros" / "controls" / "create_source_indexes.sql"

# CREATE [UNIQUE] INDEX <name> ON <schema>.<table> [USING <method>] ( <cols> )
CREATE_RE = re.compile(
    r"CREATE\s+(UNIQUE\s+)?INDEX\s+(\w+)\s+ON\s+\w+\.(\w+)\s*"
    r"(?:USING\s+(\w+)\s*)?\(([^)]+)\)",
    re.IGNORECASE,
)


def parse_indexes(sql_text: str) -> list[dict]:
    indexes: list[dict] = []
    seen: set[str] = set()
    for m in CREATE_RE.finditer(sql_text):
        is_unique = bool(m.group(1))
        name = m.group(2)
        table = m.group(3)
        method = m.group(4).lower() if m.group(4) else None
        cols = [c.strip() for c in m.group(5).split(",") if c.strip()]
        if name in seen:
            continue  # le .sql contient quelques doublons (ex. cm_ndcode1/2)
        seen.add(name)
        indexes.append(
            {
                "name": name,
                "table": table,
                "cols": cols,
                "unique": is_unique,
                "method": method,
            }
        )
    return indexes


def render_macro(indexes: list[dict]) -> str:
    lines = []
    for ix in indexes:
        cols = ", ".join(f'"{c}"' for c in ix["cols"])
        unique = "true" if ix["unique"] else "false"
        method = f'"{ix["method"]}"' if ix["method"] else "none"
        lines.append(
            f'    {{"name": "{ix["name"]}", "table": "{ix["table"]}", '
            f'"cols": [{cols}], "unique": {unique}, "method": {method}}},'
        )
    index_block = "\n".join(lines)

    return f"""{{#
  AUTO-GÉNÉRÉ par scripts/generate_index_macro.py depuis scripts/gracethd_indexes.sql
  Ne pas éditer à la main : modifier le .sql puis relancer le script.

  Crée les index sur les tables sources GRACE THD.
  - schéma source résolu dynamiquement via le graph dbt (source 'gracethd') ;
  - non-bloquant : table + colonnes vérifiées dans information_schema avant CREATE ;
  - idempotent : index déjà présents ignorés + CREATE INDEX IF NOT EXISTS.

  Appel typique (pre-hook configuré dans dbt_project.yml) :
    +pre-hook: ["{{{{ create_source_indexes() }}}}"]
#}}
{{% macro create_source_indexes() %}}
  {{%- if not execute -%}}{{{{ return('') }}}}{{%- endif -%}}

  {{%- set src_schema = (graph.sources.values()
        | selectattr('source_name', 'equalto', 'gracethd')
        | list | first).schema -%}}

  {{%- set indexes = [
{index_block}
  ] -%}}

  {{#- Colonnes réellement présentes : "table.colonne" -#}}
  {{%- set col_rows = run_query(
      "select table_name || '.' || column_name from information_schema.columns"
      ~ " where table_schema = '" ~ src_schema ~ "'"
  ) -%}}
  {{%- set existing_cols = col_rows.columns[0].values() | list if col_rows else [] -%}}

  {{#- Index déjà présents -#}}
  {{%- set idx_rows = run_query(
      "select indexname from pg_indexes where schemaname = '" ~ src_schema ~ "'"
  ) -%}}
  {{%- set existing_idx = idx_rows.columns[0].values() | list if idx_rows else [] -%}}

  {{%- for ix in indexes -%}}
    {{%- if ix.name not in existing_idx -%}}
      {{%- set ns = namespace(ok=true) -%}}
      {{%- for c in ix.cols -%}}
        {{%- if (ix.table ~ '.' ~ c) not in existing_cols -%}}{{%- set ns.ok = false -%}}{{%- endif -%}}
      {{%- endfor -%}}
      {{%- if ns.ok -%}}
        {{%- set ddl = "create " ~ ("unique " if ix.unique else "")
              ~ "index if not exists " ~ ix.name
              ~ " on " ~ src_schema ~ "." ~ ix.table
              ~ (" using " ~ ix.method if ix.method else "")
              ~ " (" ~ (ix.cols | join(", ")) ~ ")" -%}}
        {{%- do run_query(ddl) -%}}
        {{%- do log("Index créé : " ~ ix.name, info=true) -%}}
      {{%- endif -%}}
    {{%- endif -%}}
  {{%- endfor -%}}

  {{#- Corps du hook : no-op valide (les CREATE ont été exécutés via run_query) -#}}
  {{{{ return('select 1') }}}}
{{% endmacro %}}
"""


def main() -> None:
    sql_text = SRC.read_text(encoding="utf-8")
    indexes = parse_indexes(sql_text)
    DST.write_text(render_macro(indexes), encoding="utf-8")
    print(f"{len(indexes)} index → {DST.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
