{{ config(materialized='table', tags=['control']) }}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0204',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_cable',
        cle_primaire   = 'cb_code',
        attribut       = 'cb_r2_code',
        description    = "Le champ [cb_r2_code] est vide alors que le câble est de type transport ou distribution",
        requ_princ     = "SELECT cb_code, cb_r2_code, cb_typelog FROM " ~ source('gracethd', 't_cable'),
        condition      = "src.cb_r2_code IS NULL AND src.cb_typelog IN ('TR', 'DI', 'CT')"
    )
}}
