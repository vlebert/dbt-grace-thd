{{ config(materialized='table', tags=['grace_control']) }}


{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0609',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_local',
        cle_primaire = 'lc_code',
        attribut     = 'lc_prop',
        description  = "Le champ [lc_prop] est vide alors que [lc_typelog] = SRO ou NRO",
        requ_princ   = "SELECT lc_code, lc_prop, lc_typelog FROM " ~ source('gracethd', 't_local'),
        condition    = "(src.lc_prop IS NULL OR trim(src.lc_prop::text) = '') AND src.lc_typelog IN ('SRO','NRO')",
        detail_erreur = "'lc_prop IS NULL AND lc_typelog = ' || src.lc_typelog",
        is_active      = get_rc_config('ctrl_rc_0609')
    )
}}
