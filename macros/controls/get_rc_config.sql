{% macro get_rc_config(id_test) %}
  {%- set container_level = var('grace_container_level', 'C4') -%}
  {%- set target_table = ref('param_ctrl_remplissage_cond') -%}
  {%- set rc_config = run_query("
      SELECT
          actif::boolean as actif,
          conteneur_" ~ container_level ~ " as conteneur_level_val
      FROM " ~ target_table ~ " 
      WHERE id_test = '" ~ id_test ~ "'
  ") -%}

  {%- if rc_config|length > 0 and rc_config[0] %}
    {{ return(rc_config[0]['actif'] and rc_config[0]['conteneur_level_val'] == 'C') }}
  {%- else %}
    {{ return(false) }}
  {%- endif %}
{% endmacro %}
