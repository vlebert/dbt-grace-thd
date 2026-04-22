{{ config(materialized='table', tags=['control']) }}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0060',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_site',
        cle_primaire   = 'st_code',
        attribut       = 'st_avct',
        description    = "Le champ [st_avct] est vide alors que [st_typelog] = RESEAU",
        requ_princ     = "SELECT st_code, st_avct, st_typelog FROM " ~ source('gracethd', 't_site'),
        condition      = "src.st_avct IS NULL AND src.st_typelog = 'RESEAU'"
    )
}}
