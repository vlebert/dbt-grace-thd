{{ config(materialized='table', tags=['grace_control']) }}


{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0602',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_local',
        cle_primaire   = 'lc_code',
        attribut       = 'lc_bp_codf',
        description    = "Le champ [lc_bp_codf] est vide alors que [lc_typelog] = RES ou PRO",
        requ_princ     = "SELECT lc_code, lc_bp_codf, lc_typelog FROM " ~ source('gracethd', 't_local'),
        condition      = "(src.lc_bp_codf IS NULL OR trim(src.lc_bp_codf::text) = '') AND src.lc_typelog IN ('RES','PRO')",
        detail_erreur  = "'lc_bp_codf IS NULL AND lc_typelog = ' || src.lc_typelog",
        is_active      = get_rc_config('ctrl_rc_0602')
    )
}}
