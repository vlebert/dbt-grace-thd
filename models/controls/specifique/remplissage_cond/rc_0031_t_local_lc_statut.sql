{{ config(materialized='table', tags=['control']) }}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0031',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_local',
        cle_primaire = 'lc_code',
        attribut     = 'lc_statut',
        description  = "Le champ [lc_statut] est vide alors que [lc_typelog] = SRO ou NRO",
        requ_princ   = "SELECT lc_code, lc_statut, lc_typelog FROM " ~ source('gracethd', 't_local'),
        condition    = "src.lc_statut IS NULL AND src.lc_typelog IN ('SRO','NRO')",
        detail_erreur = "'lc_statut IS NULL AND lc_typelog = ' || src.lc_typelog"
    )
}}
