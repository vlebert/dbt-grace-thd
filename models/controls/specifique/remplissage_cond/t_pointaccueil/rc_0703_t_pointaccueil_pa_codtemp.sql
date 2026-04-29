{{ config(materialized='table', tags=['control']) }}


{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0703',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_pointaccueil',
        cle_primaire   = 'pa_code',
        attribut       = 'pa_codtemp',
        description    = "Le champ [pa_codtemp] est vide alors que [pa_codeext] est également vide",
        requ_princ     = "SELECT pa_code, pa_codtemp, pa_codeext FROM " ~ source('gracethd', 't_pointaccueil'),
        condition      = "src.pa_codtemp IS NULL AND src.pa_codeext IS NULL",
        is_active      = get_rc_config('ctrl_rc_0703')
    )
}}
