{{ config(materialized='table', tags=['control']) }}

{%- set container_level = var('grace_container_level', 'C3') -%}
{%- set conteneurs = {'C1': 'N', 'C2': 'N', 'C3': 'C', 'C4': 'N'} -%}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0815',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_site',
        cle_primaire   = 'st_code',
        attribut       = 'st_design',
        description    = "Le champ [st_design] est vide alors que le site est de type ADR ou SHE",
        requ_princ     = "SELECT st_code, st_design, st_typephy FROM " ~ source('gracethd', 't_site'),
        condition      = "src.st_design IS NULL AND src.st_typephy IN ('ADR', 'SHE')",
        is_active      = conteneurs[container_level] == 'C'
    )
}}
