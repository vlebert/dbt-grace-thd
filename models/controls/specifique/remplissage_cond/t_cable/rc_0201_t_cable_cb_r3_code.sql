{{ config(materialized='table', tags=['control']) }}


{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0201',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_cable',
        cle_primaire = 'cb_code',
        attribut     = 'cb_r3_code',
        description  = "Le champ [cb_r3_code] est vide alors que le câble déployé est limité à un usage distribution",
        requ_princ   = "SELECT cb_code, cb_r3_code, cb_typelog FROM " ~ source('gracethd', 't_cable'),
        condition    = "src.cb_r3_code IS NULL AND src.cb_typelog = 'DI'",
        is_active      = get_rc_config('ctrl_rc_0201')
    )
}}
