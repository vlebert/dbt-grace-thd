{{ config(materialized='table', tags=['grace_control']) }}


{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0606',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_local',
        cle_primaire   = 'lc_code',
        attribut       = 'lc_elec',
        description    = "Le champ [lc_elec] est vide alors que [lc_typelog] = SRO ou NRO",
        requ_princ     = "SELECT lc_code, lc_elec, lc_typelog FROM " ~ source('gracethd', 't_local'),
        condition      = "src.lc_elec IS NULL AND src.lc_typelog IN ('SRO','NRO')",
        detail_erreur  = "'lc_elec IS NULL AND lc_typelog = ' || src.lc_typelog",
        is_active      = get_rc_config('ctrl_rc_0606')
    )
}}
