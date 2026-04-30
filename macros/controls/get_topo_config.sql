{% macro get_topo_config(id_test) %}
  {%- set container_level = var('grace_container_level', 'C3') -%}
  {%- set target_table = ref('param_ctrl_topo') -%}
  {%- set topo_config = run_query(" 
      SELECT 
          actif::boolean as actif,
          conteneur_" ~ container_level ~ " as conteneur_level_val 
      FROM " ~ target_table ~ " 
      WHERE id_test = '" ~ id_test ~ "'
  ") -%}

  {%- if topo_config|length > 0 and topo_config[0] %}
    {{ return(topo_config[0]['actif'] and topo_config[0]['conteneur_level_val'] == 'O') }}
  {%- else %}
    {{ return(false) }}
  {%- endif %}
{% endmacro %}
