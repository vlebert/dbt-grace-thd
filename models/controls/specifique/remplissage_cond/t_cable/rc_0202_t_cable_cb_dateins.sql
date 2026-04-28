{{ config(materialized='table', tags=['control']) }}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0202',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_cable',
        cle_primaire   = 'cb_code',
        attribut       = 'cb_dateins',
        description    = "Le champ [cb_dateins] est vide alors que [cb_statut] IN ('REC','MCO')",
        requ_princ     = "SELECT cb_code, cb_dateins, cb_statut FROM " ~ source('gracethd', 't_cable'),
        condition      = "src.cb_dateins IS NULL AND src.cb_statut IN ('REC','MCO')"
    )
}}
