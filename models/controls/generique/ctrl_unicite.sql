{{ config(materialized='table', tags=['grace_control']) }}

{#
  Contrôle générique d'unicité des attributs.

  Paramétré par le seed `param_ctrl_unicite` :
    - Chaque ligne active produit une branche de l'UNION ALL.
    - Sont remontées toutes les entités dont l'attribut prend une valeur
      présente plus d'une fois dans la table (doublons).
    - Les valeurs NULL ne sont pas signalées ici : voir `ctrl_remplissage`.
#}

{%- set seed_ref = ref('param_ctrl_unicite') -%}

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
    select id_test, classe, attribut, cle_primaire
    from {{ seed_ref }}
    where actif = true
    order by id_test
  {%- endset -%}
  {%- set tests = [] -%}
  {%- for row in run_query(query).rows -%}
    {%- if row['classe'] in existing_tables -%}
      {%- do tests.append(row) -%}
    {%- endif -%}
  {%- endfor -%}
{%- else -%}
  {%- set tests = [] -%}
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

{% for test in tests %}
union all
select
  '{{ test['id_test'] }}'::text                 as id_test,
  'unicite'::text                               as type_controle,
  'Valeur dupliquée'::text                      as description,
  '{{ test['classe'] }}'::text                  as classe,
  '{{ test['attribut'] }}'::text                as attribut,
  src."{{ test['cle_primaire'] }}"::text        as id_entite,
  'Valeur : ' || doublons.code_unic
    || ' / nb occurences : ' || doublons.nb_occ::text as detail_erreur
from {{ source('gracethd', test['classe']) }} as src
join (
  select
    "{{ test['attribut'] }}"::text as code_unic,
    count(*)                       as nb_occ
  from {{ source('gracethd', test['classe']) }}
  where "{{ test['attribut'] }}" is not null
    and "{{ test['attribut'] }}" <> ''
  group by "{{ test['attribut'] }}"
  having count(*) > 1
) as doublons
  on src."{{ test['attribut'] }}"::text = doublons.code_unic
where src."{{ test['attribut'] }}" is not null
  and src."{{ test['attribut'] }}" <> ''
{% endfor %}
