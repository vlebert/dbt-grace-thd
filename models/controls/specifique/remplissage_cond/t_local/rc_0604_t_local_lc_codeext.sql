{{ config(materialized='table', tags=['grace_control']) }}


{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0604',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_local',
        cle_primaire   = 'lc_code',
        attribut       = 'lc_codeext',
        description    = "Le champ [lc_codeext] est vide alors que [lc_typelog] = SRO ou NRO",
        requ_princ     = "SELECT lc_code, lc_codeext, lc_typelog FROM " ~ source('gracethd', 't_local'),
        condition      = "src.lc_codeext IS NULL AND src.lc_typelog IN ('SRO','NRO')",
        detail_erreur  = "'lc_codeext IS NULL AND lc_typelog = ' || src.lc_typelog",
        is_active      = get_rc_config('ctrl_rc_0604')
    )
}}
