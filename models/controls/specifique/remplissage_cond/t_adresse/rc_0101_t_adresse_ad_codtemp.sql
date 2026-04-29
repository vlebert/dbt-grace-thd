{{ config(materialized='table', tags=['control']) }}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0101',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_adresse',
        cle_primaire   = 'ad_code',
        attribut       = 'ad_codtemp',
        description    = "Le code temporaire de l'adresse [ad_codtemp] est vide alors que [ad_batcode] est également vide",
        requ_princ     = "SELECT ad_code, ad_codtemp, ad_batcode FROM " ~ source('gracethd', 't_adresse'),
        condition      = "src.ad_codtemp IS NULL AND src.ad_batcode IS NULL",
        is_active      = get_rc_config('ctrl_rc_0101')
    )
}}
