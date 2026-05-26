{{ config(materialized='table', tags=['grace_rapport']) }}

{#
  Consolidation de tous les modèles de contrôle du graphe dbt.
  Tout modèle tagué grace_control (sans grace_rapport) est automatiquement inclus —
  qu'il appartienne au package ou au projet consommateur.
#}

{%- set ctrl_models = [] -%}
{%- if execute -%}
  {%- for node in graph.nodes.values() -%}
    {%- if 'grace_control' in node.tags
       and 'grace_rapport' not in node.tags
       and node.resource_type == 'model' -%}
      {%- do ctrl_models.append({'schema': node.schema, 'alias': node.alias}) -%}
    {%- endif -%}
  {%- endfor -%}
{%- endif -%}

select
  null::text as id_test,
  null::text as type_controle,
  null::text as description,
  null::text as classe,
  null::text as attribut,
  null::text as id_entite,
  null::text as detail_erreur
where false

{% for m in ctrl_models %}
union all
select * from {{ m.schema }}.{{ m.alias }}
{% endfor %}
