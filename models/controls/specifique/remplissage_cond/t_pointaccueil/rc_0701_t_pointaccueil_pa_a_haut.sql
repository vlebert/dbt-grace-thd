{{ config(materialized='table', tags=['grace_control']) }}


{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0701',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_pointaccueil',
        cle_primaire   = 'pa_code',
        attribut       = 'pa_a_haut',
        description    = "Le champ [pa_a_haut] est vide alors que [pa_typephy] = APP",
        requ_princ     = "SELECT pa_code, pa_a_haut, pa_typephy FROM " ~ source('gracethd', 't_pointaccueil'),
        condition      = "src.pa_a_haut IS NULL AND src.pa_typephy = 'APP'",
        is_active      = get_rc_config('ctrl_rc_0701')
    )
}}
