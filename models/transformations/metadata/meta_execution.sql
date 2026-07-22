{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['grace_meta'],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"]
    )
}}

{#-
  Date du jeu de données : renseignée manuellement au run, soit en ligne de
  commande (`dbt run --vars '{grace_date_donnees: 2026-07-01}'`), soit dans le
  `dbt_project.yml` du projet consommateur. Contrairement aux données sources
  (typage non-bloquant), il s'agit d'une saisie humaine ponctuelle : un format
  invalide arrête le run avec un message explicite plutôt que de produire
  silencieusement un NULL ou une date mal interprétée (ex. `01/07/2026`).
-#}
{%- set date_donnees = var('grace_date_donnees', none) -%}
{%- if date_donnees is not none -%}
  {%- set date_donnees = date_donnees | string | trim -%}
  {%- if not modules.re.match('^\d{4}-\d{2}-\d{2}$', date_donnees) -%}
    {{ exceptions.raise_compiler_error(
        "grace_date_donnees = '" ~ date_donnees ~ "' : format attendu YYYY-MM-DD "
        ~ "(ex. dbt run --vars '{grace_date_donnees: 2026-07-01}')"
    ) }}
  {%- endif -%}
{%- endif %}

SELECT
  1::int4 AS id,
  {% if date_donnees is none -%}
  CAST(NULL AS date)
  {%- else -%}
  CAST('{{ date_donnees }}' AS date)
  {%- endif %} AS date_donnees,
  CAST('{{ run_started_at }}' AS timestamptz) AS date_execution,
  CAST('{{ var("grace_container_level", "C4") }}' AS text) AS container_level,
  CAST({{ var('grace_srid', 2154) }} AS int4) AS srid
