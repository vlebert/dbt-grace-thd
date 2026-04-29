{{ config(materialized='table', tags=['control']) }}


{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0801',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_site',
        cle_primaire   = 'st_code',
        attribut       = 'st_ad_code',
        description    = "Le champ [st_ad_code] est vide alors que [st_typelog] = CLIENT",
        requ_princ     = "SELECT st_code, st_ad_code, st_typelog FROM " ~ source('gracethd', 't_site'),
        condition      = "src.st_ad_code IS NULL AND src.st_typelog = 'CLIENT'",
        is_active      = get_rc_config('ctrl_rc_0801')
    )
}}
