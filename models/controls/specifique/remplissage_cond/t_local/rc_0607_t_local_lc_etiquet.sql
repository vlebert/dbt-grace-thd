{{ config(materialized='table', tags=['grace_control']) }}


{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0607',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_local',
        cle_primaire = 'lc_code',
        attribut     = 'lc_etiquet',
        description  = "Le champ [lc_etiquet] est vide alors que [lc_typelog] = SRO ou NRO",
        requ_princ   = "SELECT lc_code, lc_etiquet, lc_typelog FROM " ~ source('gracethd', 't_local'),
        condition    = "(src.lc_etiquet IS NULL OR trim(src.lc_etiquet::text) = '') AND src.lc_typelog IN ('SRO','NRO')",
        detail_erreur = "'lc_etiquet IS NULL AND lc_typelog = ' || src.lc_typelog",
        is_active      = get_rc_config('ctrl_rc_0607')
    )
}}
