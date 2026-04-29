{{ config(materialized='table', tags=['control']) }}

{%- set container_level = var('grace_container_level', 'C3') -%}
{%- set conteneurs = {'C1': 'N', 'C2': 'N', 'C3': 'C', 'C4': 'N'} -%}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0202',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_cable',
        cle_primaire   = 'cb_code',
        attribut       = 'cb_dateins',
        description    = "Le champ [cb_dateins] est vide alors que [cb_statut] IN ('REC','MCO')",
        requ_princ     = "SELECT cb_code, cb_dateins, cb_statut FROM " ~ source('gracethd', 't_cable'),
        condition      = "src.cb_dateins IS NULL AND src.cb_statut IN ('REC','MCO')",
        is_active      = conteneurs[container_level] == 'C'
    )
}}
