{{ config(materialized='table', tags=['control']) }}

{%- set container_level = var('grace_container_level', 'C3') -%}
{%- set conteneurs = {'C1': 'N', 'C2': 'N', 'C3': 'C', 'C4': 'N'} -%}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0703',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_pointaccueil',
        cle_primaire   = 'pa_code',
        attribut       = 'pa_codtemp',
        description    = "Le champ [pa_codtemp] est vide alors que [pa_codeext] est également vide",
        requ_princ     = "SELECT pa_code, pa_codtemp, pa_codeext FROM " ~ source('gracethd', 't_pointaccueil'),
        condition      = "src.pa_codtemp IS NULL AND src.pa_codeext IS NULL",
        is_active      = conteneurs[container_level] == 'C'
    )
}}
