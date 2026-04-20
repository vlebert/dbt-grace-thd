{{ config(materialized='table', tags=['rapport']) }}

{#
  Consolidation de tous les contrôles taggés 'control'.

  Introspection du graph dbt au parse : chaque modèle portant le tag 'control'
  est intégré automatiquement dans l'UNION ALL. Aucune liste manuelle à
  maintenir - il suffit de créer un nouveau modèle avec `tags=['control']`
  pour qu'il soit inclus.

  Ce modèle ne contient pas de géométrie. Pour une restitution géolocalisée,
  utiliser `rapport_controles_geo` qui résout la geom via (classe, id_entite).
#}

{%- set control_nodes = [] -%}
{%- for node in graph.nodes.values() -%}
  {%- if 'control' in node.config.tags -%}
    {%- do control_nodes.append(node) -%}
  {%- endif -%}
{%- endfor %}

-- Placeholder : garantit un schéma stable même si aucun contrôle n'existe
select
  null::text as id_test,
  null::text as type_controle,
  null::text as description,
  null::text as classe,
  null::text as attribut,
  null::text as id_entite,
  null::text as detail_erreur
where false

{% for node in control_nodes %}
union all
select * from {{ ref(node.name) }}
{% endfor %}
