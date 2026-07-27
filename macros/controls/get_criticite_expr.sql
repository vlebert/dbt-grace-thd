{#
  Retourne l'expression SQL calculant la criticité d'une ligne de rapport à
  partir de son `id_test`.

  La criticité n'est pas portée par les modèles de contrôle : elle est attribuée
  au moment de la consolidation (`rapport_controles`), au même titre que la
  géométrie qui est résolue en aval. Un contrôle n'a donc pas à connaître son
  propre niveau de gravité, qui relève d'un arbitrage projet.

  Paramétrage (dbt_project.yml du projet consommateur) :

      vars:
        grace_criticite_defaut: "mineure"
        grace_criticite:
          majeure:
            - ctrl_rem_0001
            - ctrl_fk_0002
          bloquante:
            - topo_0001
          "à valider MOE":      # libellé libre autorisé
            - ctrl_lv_0012

  Les libellés `mineure` / `majeure` / `bloquante` sont conventionnels : toute
  autre chaîne est acceptée. Aucun libellé n'a d'effet sur le run — `bloquante`
  n'interrompt rien, conformément au principe d'intégration non bloquante du
  package. Les ids sont comparés sans tenir compte de la casse.

  Les deux variables sont déclarées dans le `dbt_project.yml` du package et lues
  ici sans valeur de repli : ce fichier n'est pas une seconde source de vérité.
#}

{% macro get_criticite_expr(id_test_col='id_test') %}

  {%- set defaut = var('grace_criticite_defaut') -%}
  {%- if defaut is not string or defaut | trim == '' -%}
    {{ exceptions.raise_compiler_error(
        "grace_criticite_defaut doit être un libellé texte non vide (ex. 'mineure')."
    ) }}
  {%- endif -%}
  {%- set defaut = defaut | trim -%}

  {%- set surcharges = var('grace_criticite') or {} -%}
  {%- if surcharges is not mapping -%}
    {{ exceptions.raise_compiler_error(
        "grace_criticite doit être un dictionnaire {libellé de criticité: [id_test, ...]}, "
        ~ "par exemple {majeure: [ctrl_rem_0001], bloquante: [topo_0001]}."
    ) }}
  {%- endif -%}

  {#- Normalisation en une liste de branches, avec détection des id_test
      affectés à deux criticités différentes (l'ordre du YAML ne doit pas
      arbitrer silencieusement). -#}
  {%- set branches = [] -%}
  {%- set libelle_par_id = {} -%}

  {%- for libelle, ids in surcharges.items() -%}

    {%- if libelle is not string or libelle | trim == '' -%}
      {{ exceptions.raise_compiler_error(
          "grace_criticite : les clés doivent être des libellés texte non vides."
      ) }}
    {%- endif -%}
    {%- set libelle = libelle | trim -%}

    {#- Tolérance : un id seul peut être écrit sans liste. -#}
    {%- set ids = [ids] if ids is string else ids -%}
    {%- if ids is mapping or ids is not sequence -%}
      {{ exceptions.raise_compiler_error(
          "grace_criticite['" ~ libelle ~ "'] doit être une liste d'id_test "
          ~ "(ou un id_test unique), et non " ~ ids | string ~ "."
      ) }}
    {%- endif -%}

    {%- set ids_branche = [] -%}
    {%- for id_test in ids -%}
      {%- if id_test is not string or id_test | trim == '' -%}
        {{ exceptions.raise_compiler_error(
            "grace_criticite['" ~ libelle ~ "'] contient un id_test vide ou non textuel."
        ) }}
      {%- endif -%}
      {%- set id_norm = id_test | trim | lower -%}
      {%- if id_norm in libelle_par_id and libelle_par_id[id_norm] != libelle -%}
        {{ exceptions.raise_compiler_error(
            "grace_criticite : l'id_test '" ~ id_norm ~ "' est affecté à deux criticités "
            ~ "différentes ('" ~ libelle_par_id[id_norm] ~ "' et '" ~ libelle ~ "'). "
            ~ "Un contrôle ne peut porter qu'une seule criticité."
        ) }}
      {%- endif -%}
      {%- if id_norm not in libelle_par_id -%}
        {%- do libelle_par_id.update({id_norm: libelle}) -%}
        {%- do ids_branche.append(id_norm) -%}
      {%- endif -%}
    {%- endfor -%}

    {%- if ids_branche | length > 0 -%}
      {%- do branches.append({'libelle': libelle, 'ids': ids_branche}) -%}
    {%- endif -%}

  {%- endfor -%}

  {#- Les libellés étant du texte libre (apostrophes possibles), on reprend le
      dollar-quoting utilisé par `ctrl_specifique`. -#}
  {%- for valeur in [defaut] + (branches | map(attribute='libelle') | list)
                    + (libelle_par_id | list) -%}
    {%- if '$str$' in valeur -%}
      {{ exceptions.raise_compiler_error(
          "grace_criticite : la valeur '" ~ valeur ~ "' contient la séquence réservée $str$."
      ) }}
    {%- endif -%}
  {%- endfor -%}

  {%- if branches | length == 0 -%}
    {#- Aucune surcharge : littéral constant plutôt qu'un CASE inutile. -#}
$str${{ defaut }}$str$::text
  {%- else -%}
case
  {%- for branche in branches %}
    when lower({{ id_test_col }}) in (
      {%- for id_test in branche.ids -%}
        $str${{ id_test }}$str${{ ', ' if not loop.last }}
      {%- endfor -%}
    ) then $str${{ branche.libelle }}$str$
  {%- endfor %}
    else $str${{ defaut }}$str$
end::text
  {%- endif -%}

{% endmacro %}
