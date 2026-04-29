{{ config(materialized='table', tags=['control']) }}


{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0301',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_cassette',
        cle_primaire   = 'cs_code',
        attribut       = 'cs_bp_code',
        description    = "Le champ [cs_bp_code] est vide alors que la cassette est de type Epissure",
        requ_princ     = "SELECT cs_code, cs_bp_code, cs_type FROM " ~ source('gracethd', 't_cassette'),
        condition      = "src.cs_bp_code IS NULL AND src.cs_type = 'E'",
        is_active      = get_rc_config('ctrl_rc_0301')
    )
}}
