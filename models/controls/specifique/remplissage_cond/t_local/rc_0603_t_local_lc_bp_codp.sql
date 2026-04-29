{{ config(materialized='table', tags=['control']) }}


{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0603',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_local',
        cle_primaire   = 'lc_code',
        attribut       = 'lc_bp_codp',
        description    = "Le champ [lc_bp_codp] est vide alors que [lc_typelog] = ENT",
        requ_princ     = "SELECT lc_code, lc_bp_codp, lc_typelog FROM " ~ source('gracethd', 't_local'),
        condition      = "src.lc_bp_codp IS NULL AND src.lc_typelog = 'ENT'",
        is_active      = get_rc_config('ctrl_rc_0603')
    )
}}
