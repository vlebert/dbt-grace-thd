
{#
  Contrôle générique de cohérence des clés étrangères.

  Paramétré par le seed `ctrl_fk` :
    - Chaque ligne active (actif = true) produit une branche de l'UNION ALL.
    - Seules les entités dont l'attribut FK est non NULL mais absent de la table
      cible sont remontées (erreur d'intégrité référentielle).
    - Les attributs NULL ne sont pas signalés ici : leur caractère obligatoire
      est vérifié par `ctrl_remplissage`.

  Note t_cab_chem : table de jonction sans PK mono-colonne ; `cle_primaire`
  vaut `cc_cb_code` par convention (identifie le câble impliqué).
#}

{%- set seed_ref = ref('param_ctrl_fk') -%}

{%- if execute -%}
  {%- set query -%}
    select id_test, classe, attribut, cle_primaire, classe_cible, attribut_cible
    from {{ seed_ref }}
    where actif = true
    order by id_test
  {%- endset -%}
  {%- set results = run_query(query) -%}
  {%- set tests = results.rows if results else [] -%}
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
  '{{ test['id_test'] }}'::text                   as id_test,
  'relations'::text                               as type_controle,
  'Clé étrangère invalide'::text                  as description,
  '{{ test['classe'] }}'::text                    as classe,
  '{{ test['attribut'] }}'::text                  as attribut,
  src."{{ test['cle_primaire'] }}"::text          as id_entite,
  '{{ test['attribut'] }}: ' || src."{{ test['attribut'] }}"::text as detail_erreur
from {{ source('gracethd', test['classe']) }} as src
where src."{{ test['attribut'] }}" is not null
  and src."{{ test['attribut'] }}" <> ''
  and not exists (
    select 1
    from {{ source('gracethd', test['classe_cible']) }} as tgt
    where tgt."{{ test['attribut_cible'] }}" = src."{{ test['attribut'] }}"
  )
{% endfor %}
