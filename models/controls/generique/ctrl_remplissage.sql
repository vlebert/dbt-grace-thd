
{#
  Contrôle générique de remplissage des attributs obligatoires.

  Paramétré par le seed `ctrl_remplissage` :
    - Chaque ligne active (actif = true) produit une branche de l'UNION ALL.
    - La branche est générée uniquement si l'attribut est obligatoire ('O') au
      niveau de conteneur courant (var `grace_container_level`, ex. 'C3').

  Une ligne de résultat est produite par entité en défaut (valeur NULL ou
  chaîne vide). Le modèle ne porte PAS de géométrie : la géolocalisation est
  gérée en aval par `rapport_controles_geo` à partir de (classe, id_entite).
#}

{%- set seed_ref = ref('param_ctrl_remplissage') -%}

{%- set container_level = var('grace_container_level', 'C3') | lower -%}
{%- set container_col = 'conteneur_' ~ container_level -%}

{%- if execute -%}
  {%- set query -%}
    select id_test, classe, attribut, cle_primaire
    from {{ seed_ref }}
    where actif = true
      and {{ container_col }} = 'O'
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
  '{{ test['id_test'] }}'::text                 as id_test,
  'remplissage'::text                           as type_controle,
  'Attribut obligatoire non renseigné'::text    as description,
  '{{ test['classe'] }}'::text                  as classe,
  '{{ test['attribut'] }}'::text                as attribut,
  src."{{ test['cle_primaire'] }}"::text        as id_entite,
  null::text                                    as detail_erreur
from {{ source('gracethd', test['classe']) }} as src
where src."{{ test['attribut'] }}" is null
   or trim(src."{{ test['attribut'] }}"::text) = ''
{% endfor %}
