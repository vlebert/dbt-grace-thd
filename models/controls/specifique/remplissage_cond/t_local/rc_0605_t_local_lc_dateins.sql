{{ config(materialized='table', tags=['control']) }}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0605',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_local',
        cle_primaire   = 'lc_code',
        attribut       = 'lc_dateins',
        description    = "Le champ [lc_dateins] est vide alors que [lc_typelog] = SRO ou NRO ET [lc_statut] IN ('REC','MCO')",
        requ_princ     = "SELECT lc_code, lc_dateins, lc_typelog, lc_statut FROM " ~ source('gracethd', 't_local'),
        condition      = "src.lc_dateins IS NULL AND src.lc_typelog IN ('SRO','NRO') AND src.lc_statut IN ('REC','MCO')",
        detail_erreur  = "'lc_typelog = ' || src.lc_typelog || ' / lc_statut = ' || src.lc_statut"
    )
}}
