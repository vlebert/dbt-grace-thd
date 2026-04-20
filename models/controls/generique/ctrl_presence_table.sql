{{ config(materialized='table', tags=['control']) }}

{#
  Contrôle de présence et de remplissage des tables obligatoires GRACE THD.

  Paramétré par le seed `param_ctrl_presence_table` :
    - Seules les tables obligatoires ('O') au niveau de conteneur courant
      (var `grace_container_level`) sont contrôlées.
    - Deux anomalies possibles par table :
        • 'Table absente'  : la table n'existe pas dans le schéma source.
        • 'Table vide'     : la table existe mais ne contient aucune ligne.
#}

{%- set seed_ref = ref('param_ctrl_presence_table') -%}
{%- set container_level = var('grace_container_level', 'C3') | lower -%}
{%- set container_col   = 'conteneur_' ~ container_level -%}

{%- if execute -%}
  {%- set src_schema = (graph.sources.values()
        | selectattr('source_name', 'equalto', 'gracethd')
        | list | first).schema -%}

  {%- set existing_result = run_query(
        "select table_name from information_schema.tables where table_schema = '"
        ~ src_schema ~ "'"
      ) -%}
  {%- set existing_tables = existing_result.columns[0].values() if existing_result else [] -%}

  {%- set query -%}
    select id_test, classe, cle_primaire
    from {{ seed_ref }}
    where actif = true
      and {{ container_col }} = 'O'
    order by id_test
  {%- endset -%}

  {%- set absent_tests = [] -%}
  {%- set empty_tests  = [] -%}
  {%- for row in run_query(query).rows -%}
    {%- if row['classe'] in existing_tables -%}
      {%- do empty_tests.append(row) -%}
    {%- else -%}
      {%- do absent_tests.append(row) -%}
    {%- endif -%}
  {%- endfor -%}
{%- else -%}
  {%- set absent_tests = [] -%}
  {%- set empty_tests  = [] -%}
{%- endif %}

select
  null::text as id_test,
  null::text as type_controle,
  null::text as description,
  null::text as classe,
  null::text as attribut,
  null::text as id_entite,
  null::text as detail_erreur
where false

{% for test in absent_tests %}
union all
select
  '{{ test['id_test'] }}'::text                as id_test,
  'presence_table'::text                       as type_controle,
  'Table obligatoire non disponible'::text     as description,
  '{{ test['classe'] }}'::text                 as classe,
  null::text                                   as attribut,
  null::text                                   as id_entite,
  'Table absente du schéma source'::text       as detail_erreur
{% endfor %}

{% for test in empty_tests %}
union all
select
  '{{ test['id_test'] }}'::text                as id_test,
  'presence_table'::text                       as type_controle,
  'Table obligatoire non disponible'::text     as description,
  '{{ test['classe'] }}'::text                 as classe,
  null::text                                   as attribut,
  null::text                                   as id_entite,
  'Table présente mais vide'::text             as detail_erreur
from {{ source('gracethd', test['classe']) }}
having count(*) = 0
{% endfor %}
