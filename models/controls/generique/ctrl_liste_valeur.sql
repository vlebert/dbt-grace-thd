{{ config(materialized='table', tags=['grace_control']) }}

{#
  Contrôle générique de conformité aux listes de valeurs.

  Paramétré par le seed `ctrl_liste_valeur` :
    - Chaque ligne active (actif = true) produit une branche de l'UNION ALL.
    - Seules les entités dont l'attribut est non NULL mais absent du référentiel
      `table_liste` (colonne `code`) sont remontées.
    - Les attributs NULL ne sont pas signalés ici : voir `ctrl_remplissage`.

  Les seeds de listes de valeurs (l_*) sont chargés dans le schéma
  `<target.schema>` (par défaut).
#}

{%- set seed_ref = ref('param_ctrl_liste_valeur') -%}

{%- if execute -%}
  {%- set query -%}
    select id_test, classe, attribut, cle_primaire, table_liste
    from {{ seed_ref }}
    where actif = true
    order by id_test
  {%- endset -%}
  {%- set results = run_query(query) -%}
  {%- set tests = results.rows if results else [] -%}
{%- else -%}
  {%- set tests = [] -%}
{%- endif %}

{%- set listes_schema = target.schema -%}

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
  '{{ test['id_test'] }}'::text                   as id_test,
  'liste_valeurs'::text                           as type_controle,
  'Valeur absente du référentiel'::text           as description,
  '{{ test['classe'] }}'::text                    as classe,
  '{{ test['attribut'] }}'::text                  as attribut,
  src."{{ test['cle_primaire'] }}"::text          as id_entite,
  '{{ test['attribut'] }}: ' || src."{{ test['attribut'] }}"::text as detail_erreur
from {{ source('gracethd', test['classe']) }} as src
where src."{{ test['attribut'] }}" is not null
  and src."{{ test['attribut'] }}"::text <> ''
  and not exists (
    select 1
    from {{ listes_schema }}.{{ test['table_liste'] }} as ref_lv
    where ref_lv.code = src."{{ test['attribut'] }}"::text
  )
{% endfor %}
