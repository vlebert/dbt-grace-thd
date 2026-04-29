{{ config(materialized='table', tags=['control']) }}

{%- set container_level = var('grace_container_level', 'C3') -%}
{%- set conteneurs = {'C1': 'N', 'C2': 'N', 'C3': 'C', 'C4': 'N'} -%}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0501',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_ebp',
        cle_primaire   = 'bp_code',
        attribut       = 'bp_dateins',
        description    = "Le champ [bp_dateins] est vide alors que [bp_statut] IN ('REC','MCO')",
        requ_princ     = "SELECT bp_code, bp_dateins, bp_statut FROM " ~ source('gracethd', 't_ebp'),
        condition      = "src.bp_dateins IS NULL AND src.bp_statut IN ('REC','MCO')",
        is_active      = conteneurs[container_level] == 'C'
    )
}}
