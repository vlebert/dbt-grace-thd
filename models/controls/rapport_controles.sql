{{ config(materialized='table', tags=['control', 'rapport']) }}

{#
  Consolidation de tous les contrôles déclarés dans la var `grace_ctrl_models`.

  Pour ajouter un contrôle personnalisé, étendre la var dans dbt_project.yml :
    vars:
      grace_ctrl_models:
        - ctrl_mon_controle

  Les modèles du package sont déclarés dans sa propre section vars.
  dbt génère les depends_on depuis cette liste → `+rapport_controles` fonctionne.
#}

{%- set ctrl_models = var('grace_ctrl_models', []) + var('grace_ctrl_models_ext', []) -%}

{% for m in ctrl_models %}
-- depends_on: {{ ref(m) }}
{% endfor %}

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
select * from {{ ref(m) }}
{% endfor %}
