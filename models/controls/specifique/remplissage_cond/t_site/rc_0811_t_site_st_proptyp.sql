{{ config(materialized='table', tags=['grace_control']) }}


{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0811',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_site',
        cle_primaire   = 'st_code',
        attribut       = 'st_proptyp',
        description    = "Le champ [st_proptyp] est vide alors que [st_typelog] = RESEAU",
        requ_princ     = "SELECT st_code, st_proptyp, st_typelog FROM " ~ source('gracethd', 't_site'),
        condition      = "(src.st_proptyp IS NULL OR trim(src.st_proptyp::text) = '') AND src.st_typelog = 'RESEAU'",
        is_active      = get_rc_config('ctrl_rc_0811')
    )
}}
