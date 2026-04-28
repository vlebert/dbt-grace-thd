{{ config(materialized='table', tags=['control']) }}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0202',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_cable',
        cle_primaire   = 'cb_code',
        attribut       = 'cb_dateins',
        description    = "Valeur nulle pour un attribut obligatoire avec condition d'avancement",
        requ_princ     = "SELECT cb_code, cb_dateins as attribut, cb_statut as statut, cb_avct as avct FROM " ~ source('gracethd', 't_cable'),
        condition      = "src.statut = 'REC' AND src.avct IN ('E', 'S') AND src.attribut IS NULL"
    )
}}
