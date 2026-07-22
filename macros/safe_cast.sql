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

  Implémentation : `ST_CollectionExtract` ne conserve que les composants de la
  dimension visée, ce qui neutralise les GEOMETRYCOLLECTION hétérogènes (typiquement
  celles produites par `ST_LineMerge` sur une multiligne contenant un tronçon
  dégénéré). `ST_Multi` seul ne suffit pas : il laisse une collection inchangée, et
  le contrôle de typmod PostGIS lève alors une erreur *dure* que `pg_input_is_valid`
  n'intercepte pas (« Geometry type (GeometryCollection) does not match column type »).
  Le résultat vide (aucun composant du bon type) est ramené à NULL.

  SRID par défaut : var projet `grace_srid` (source de vérité unique).

  Usage : {{ safe_geom('MultiLineString') }} AS geom
#}
{% macro safe_geom(geom_type, col='geom', srid=none) -%}
{%- set dims = {'multipoint': 1, 'multilinestring': 2, 'multipolygon': 3} -%}
{%- set dim = dims.get(geom_type | lower) -%}
{%- if dim is none -%}
  {{ exceptions.raise_compiler_error("safe_geom : type géométrique non supporté '" ~ geom_type ~ "' (attendu MultiPoint, MultiLineString ou MultiPolygon)") }}
{%- endif -%}
{%- set srid = srid if srid is not none else var('grace_srid', 2154) -%}
CAST(
  CASE
    WHEN ST_SRID({{ col }}) = {{ srid }}
     AND NOT ST_IsEmpty(ST_CollectionExtract({{ col }}, {{ dim }}))
    THEN ST_Multi(ST_CollectionExtract({{ col }}, {{ dim }}))
    ELSE NULL
  END AS geometry({{ geom_type }}, {{ srid }})
)
{%- endmacro %}
