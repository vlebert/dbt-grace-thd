{{ config(materialized='table', tags=['control']) }}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0020',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_local',
        cle_primaire   = 'lc_code',
        attribut       = 'lc_bp_codf',
        description    = "Le champ [lc_bp_codf] est vide alors que [lc_typelog] = RES ou PRO",
        requ_princ     = "SELECT lc_code, lc_bp_codf, lc_typelog FROM " ~ source('gracethd', 't_local'),
        condition      = "src.lc_bp_codf IS NULL AND src.lc_typelog IN ('RES','PRO')",
        detail_erreur  = "'lc_bp_codf IS NULL AND lc_typelog = ' || src.lc_typelog"
    )
}}
