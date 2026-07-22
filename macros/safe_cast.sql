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

{#
  Typage géométrique non bloquant.

  Les colonnes `geom` des sources sont en `geometry(Geometry, <srid>)` (générique) ;
  ce helper normalise en multi (comme PROMOTE_TO_MULTI) et contraint au type attendu.
  Si la géométrie ne correspond pas au type/SRID cible, renvoie NULL au lieu d'échouer
  (même logique non bloquante que safe_int/safe_numeric).

  SRID par défaut : var projet `grace_srid` (source de vérité unique).

  Usage : {{ safe_geom('MultiLineString') }} AS geom
#}
{% macro safe_geom(geom_type, col='geom', srid=none) -%}
{%- set srid = srid if srid is not none else var('grace_srid', 2154) -%}
CAST(
  CASE
    WHEN pg_input_is_valid(NULLIF(ST_AsEWKT(ST_Multi({{ col }})), ''), 'geometry({{ geom_type }},{{ srid }})')
    THEN ST_Multi({{ col }})
    ELSE NULL
  END AS geometry({{ geom_type }}, {{ srid }})
)
{%- endmacro %}
