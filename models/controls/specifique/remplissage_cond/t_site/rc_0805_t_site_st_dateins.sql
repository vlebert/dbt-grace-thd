{{ config(materialized='table', tags=['grace_control']) }}


{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0805',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_site',
        cle_primaire   = 'st_code',
        attribut       = 'st_dateins',
        description    = "Le champ [st_dateins] est vide alors que [st_typelog] = 'RESEAU' ET [st_statut] IN ('REC','MCO')",
        requ_princ     = "SELECT st_code, st_dateins, st_typelog, st_statut FROM " ~ source('gracethd', 't_site'),
        condition      = "src.st_dateins IS NULL AND src.st_typelog = 'RESEAU' AND src.st_statut IN ('REC','MCO')",
        detail_erreur  = "'st_typelog = ' || src.st_typelog || ' / st_statut = ' || src.st_statut",
        is_active      = get_rc_config('ctrl_rc_0805')
    )
}}
