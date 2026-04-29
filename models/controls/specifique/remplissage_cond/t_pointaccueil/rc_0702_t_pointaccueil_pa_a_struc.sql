{{ config(materialized='table', tags=['control']) }}

{%- set container_level = var('grace_container_level', 'C3') -%}
{%- set conteneurs = {'C1': 'N', 'C2': 'N', 'C3': 'C', 'C4': 'N'} -%}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0702',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_pointaccueil',
        cle_primaire   = 'pa_code',
        attribut       = 'pa_a_struc',
        description    = "Le champ [pa_a_struc] est vide alors que [pa_typephy] = APP",
        requ_princ     = "SELECT pa_code, pa_a_struc, pa_typephy FROM " ~ source('gracethd', 't_pointaccueil'),
        condition      = "src.pa_a_struc IS NULL AND src.pa_typephy = 'APP'",
        is_active      = conteneurs[container_level] == 'C'
    )
}}
