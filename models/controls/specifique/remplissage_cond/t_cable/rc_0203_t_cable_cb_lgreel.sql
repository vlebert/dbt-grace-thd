{{ config(materialized='table', tags=['grace_control']) }}


{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0203',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_cable',
        cle_primaire   = 'cb_code',
        attribut       = 'cb_lgreel',
        description    = "Le champ [cb_lgreel] est vide alors que le câble est extrasite (cb_nd1 != cb_nd2)",
        requ_princ     = "SELECT cb_code, cb_lgreel, cb_nd1, cb_nd2 FROM " ~ source('gracethd', 't_cable'),
        condition      = "src.cb_lgreel IS NULL AND src.cb_nd1 != src.cb_nd2",
        is_active      = get_rc_config('ctrl_rc_0203')
    )
}}
