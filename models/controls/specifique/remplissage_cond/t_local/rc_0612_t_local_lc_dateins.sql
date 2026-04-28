{{ config(materialized='table', tags=['control']) }}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0612',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_local',
        cle_primaire   = 'lc_code',
        attribut       = 'lc_dateins',
        description    = "Valeur nulle pour un attribut obligatoire avec condition d'avancement",
        requ_princ     = "SELECT lc_code, lc_dateins as attribut, lc_statut as statut, lc_avct as avct FROM " ~ source('gracethd', 't_local'),
        condition      = "src.statut = 'REC' AND (src.avct = 'E' OR src.avct = 'S') AND (src.attribut IS NULL)"
    )
}}
