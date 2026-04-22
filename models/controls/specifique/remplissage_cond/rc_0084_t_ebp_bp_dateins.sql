{{ config(materialized='table', tags=['control']) }}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0084',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_ebp',
        cle_primaire   = 'bp_code',
        attribut       = 'bp_dateins',
        description    = "Valeur nulle pour un attribut obligatoire avec condition d'avancement",
        requ_princ     = "SELECT bp_code, bp_dateins as attribut, bp_statut as statut, bp_avct as avct FROM " ~ source('gracethd', 't_ebp'),
        condition      = "src.statut = 'REC' AND (src.avct = 'E' OR src.avct = 'S') AND (src.attribut IS NULL)"
    )
}}
