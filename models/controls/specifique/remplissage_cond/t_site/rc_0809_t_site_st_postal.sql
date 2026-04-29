{{ config(materialized='table', tags=['control']) }}


{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0809',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_site',
        cle_primaire   = 'st_code',
        attribut       = 'st_postal',
        description    = "Le champ [st_postal] est vide alors que [st_typelog] = RESEAU",
        requ_princ     = "SELECT st_code, st_postal, st_typelog FROM " ~ source('gracethd', 't_site'),
        condition      = "src.st_postal IS NULL AND src.st_typelog = 'RESEAU'",
        is_active      = get_rc_config('ctrl_rc_0809')
    )
}}
