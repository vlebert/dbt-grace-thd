{{ config(materialized='table', tags=['control']) }}

{%- set container_level = var('grace_container_level', 'C3') -%}
{%- set conteneurs = {'C1': 'N', 'C2': 'N', 'C3': 'C', 'C4': 'N'} -%}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0801',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_site',
        cle_primaire   = 'st_code',
        attribut       = 'st_ad_code',
        description    = "Le champ [st_ad_code] est vide alors que [st_typelog] = CLIENT",
        requ_princ     = "SELECT st_code, st_ad_code, st_typelog FROM " ~ source('gracethd', 't_site'),
        condition      = "src.st_ad_code IS NULL AND src.st_typelog = 'CLIENT'",
        is_active      = conteneurs[container_level] == 'C'
    )
}}
