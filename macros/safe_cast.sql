{#
  Cast numérique non bloquant depuis une source en `text`.

  Les tables `gracethd_source` sont chargées en `text` brut (import sans altération) ;
  tout contrôle qui fait de l'arithmétique ou une comparaison numérique sur une colonne
  source doit donc caster explicitement. Ces helpers renvoient NULL si la valeur n'est
  pas convertible (au lieu de faire échouer la requête), comme la couche `base`.
#}

{% macro safe_int(expr) -%}
CASE WHEN pg_input_is_valid(NULLIF(({{ expr }})::text, ''), 'integer') THEN ({{ expr }})::int ELSE NULL END
{%- endmacro %}

{% macro safe_numeric(expr) -%}
CASE WHEN pg_input_is_valid(NULLIF(({{ expr }})::text, ''), 'numeric') THEN ({{ expr }})::numeric ELSE NULL END
{%- endmacro %}
