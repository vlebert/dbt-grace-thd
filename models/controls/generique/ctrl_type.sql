
{#
  Contrôle générique de vérification des types d'attributs.

  Paramétré par le seed `param_ctrl_type` :
    - Chaque ligne active (actif = true) produit une branche de l'UNION ALL.
    - Utilise pg_input_is_valid() (PostgreSQL 16+) pour un test non bloquant.
#}

{%- set src_schema = (graph.sources.values()
      | selectattr('source_name', 'equalto', 'gracethd')
      | list | first).schema -%}

{%- set seed_ref = ref('param_ctrl_type') -%}

{%- if execute -%}
  {%- set query -%}
    select id_test, classe, attribut, type_cible, cle_primaire
    from {{ seed_ref }}
    where actif = true
      and exists (
        select 1
        from information_schema.tables
        where table_schema = '{{ src_schema }}'
          and table_name = classe
      )
    order by id_test
  {%- endset -%}
  {%- set results = run_query(query) -%}
  {%- set tests = results.rows if results else [] -%}
{%- else -%}
  {%- set tests = [] -%}
{%- endif %}

-- Placeholder : garantit un schéma de sortie stable même si aucun test actif
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
  '{{ test['id_test'] }}'::text as id_test,
  'verification_type'::text as type_controle,
  'Type invalide pour [' || '{{ test['attribut'] }}' || ']'::text as description,
  '{{ test['classe'] }}'::text as classe,
  '{{ test['attribut'] }}'::text as attribut,
  src.{{ test['cle_primaire'] }}::text as id_entite,
  'La valeur [' || COALESCE(src.{{ test['attribut'] }}::text, 'NULL') || '] n''est pas compatible avec le type cible ' || upper('{{ test['type_cible'] }}') as detail_erreur
from {{ source('gracethd', test['classe']) }} as src
where NOT pg_input_is_valid(src.{{ test['attribut'] }}::text, '{{ test['type_cible'] }}')
  and src.{{ test['attribut'] }} IS NOT NULL
  and trim(src.{{ test['attribut'] }}::text) != ''
{% endfor %}
