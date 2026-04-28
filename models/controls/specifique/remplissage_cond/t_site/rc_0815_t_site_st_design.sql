{{ config(materialized='table', tags=['control']) }}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0815',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_site',
        cle_primaire   = 'st_code',
        attribut       = 'st_design',
        description    = "Le champ [st_design] est vide alors que le site est de type ADR ou SHE",
        requ_princ     = "SELECT st_code, st_design, st_typephy FROM " ~ source('gracethd', 't_site'),
        condition      = "src.st_design IS NULL AND src.st_typephy IN ('ADR', 'SHE')"
    )
}}
