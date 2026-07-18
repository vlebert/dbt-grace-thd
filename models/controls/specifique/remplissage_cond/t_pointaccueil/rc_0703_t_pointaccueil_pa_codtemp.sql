{{ config(materialized='table', tags=['grace_control']) }}


{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0703',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_pointaccueil',
        cle_primaire   = 'pa_code',
        attribut       = 'pa_codtemp',
        description    = "Le champ [pa_codtemp] est vide alors que [pa_codeext] est également vide",
        requ_princ     = "SELECT pa_code, pa_codtemp, pa_codeext FROM " ~ source('gracethd', 't_pointaccueil'),
        condition      = "(src.pa_codtemp IS NULL OR trim(src.pa_codtemp::text) = '') AND (src.pa_codeext IS NULL OR trim(src.pa_codeext::text) = '')",
        is_active      = get_rc_config('ctrl_rc_0703')
    )
}}
