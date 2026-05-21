{{ config(materialized='table', tags=['grace_control']) }}


{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0501',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_ebp',
        cle_primaire   = 'bp_code',
        attribut       = 'bp_dateins',
        description    = "Le champ [bp_dateins] est vide alors que [bp_statut] IN ('REC','MCO')",
        requ_princ     = "SELECT bp_code, bp_dateins, bp_statut FROM " ~ source('gracethd', 't_ebp'),
        condition      = "src.bp_dateins IS NULL AND src.bp_statut IN ('REC','MCO')",
        is_active      = get_rc_config('ctrl_rc_0501')
    )
}}
