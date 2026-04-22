{{ config(materialized='table', tags=['control']) }}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0027',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_local',
        cle_primaire = 'lc_code',
        attribut     = 'lc_etiquet',
        description  = "Le champ [lc_etiquet] est vide alors que [lc_typelog] = SRO ou NRO",
        requ_princ   = "SELECT lc_code, lc_etiquet, lc_typelog FROM " ~ source('gracethd', 't_local'),
        condition    = "src.lc_etiquet IS NULL AND src.lc_typelog IN ('SRO','NRO')",
        detail_erreur = "'lc_etiquet IS NULL AND lc_typelog = ' || src.lc_typelog"
    )
}}
