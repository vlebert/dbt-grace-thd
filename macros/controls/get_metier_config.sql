{% macro get_metier_config(id_test) %}
  {%- set container_level = var('grace_container_level', 'C4') -%}
  {%- set target_table = ref('param_ctrl_metier') -%}
  {%- set metier_config = run_query(" 
      SELECT 
          actif::boolean as actif,
          conteneur_" ~ container_level ~ " as conteneur_level_val 
      FROM " ~ target_table ~ " 
      WHERE id_test = '" ~ id_test ~ "'
  ") -%}

  {%- if metier_config|length > 0 and metier_config[0] %}
    {{ return(metier_config[0]['actif'] and metier_config[0]['conteneur_level_val'] == 'O') }}
  {%- else %}
    {{ return(false) }}
  {%- endif %}
{% endmacro %}
