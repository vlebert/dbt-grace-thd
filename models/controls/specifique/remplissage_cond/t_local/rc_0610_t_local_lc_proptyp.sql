{{ config(materialized='table', tags=['control']) }}

{%- set container_level = var('grace_container_level', 'C3') -%}
{%- set conteneurs = {'C1': 'N', 'C2': 'N', 'C3': 'C', 'C4': 'N'} -%}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0610',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_local',
        cle_primaire = 'lc_code',
        attribut     = 'lc_proptyp',
        description  = "Le champ [lc_proptyp] est vide alors que [lc_typelog] = SRO ou NRO et [st_typelog] = CLIENT",
        requ_princ   = "SELECT lc_code, lc_proptyp, lc_typelog, st_typelog FROM " ~ source('gracethd', 't_local') ~ " LEFT JOIN " ~ source('gracethd', 't_site') ~ " ON t_local.lc_st_code = t_site.st_code",
        condition    = "src.lc_proptyp IS NULL AND src.st_typelog = 'CLIENT' AND src.lc_typelog IN ('SRO','NRO')",
        detail_erreur = "'lc_proptyp IS NULL AND lc_typelog = ' || src.lc_typelog",
        is_active      = conteneurs[container_level] == 'C'
    )
}}
