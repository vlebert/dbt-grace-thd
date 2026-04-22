{{ config(materialized='table', tags=['control']) }}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0086',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_site',
        cle_primaire   = 'st_code',
        attribut       = 'st_dateins',
        description    = "Valeur nulle pour un attribut obligatoire avec condition d'avancement",
        requ_princ     = "SELECT st_code, st_dateins as attribut, st_statut as statut, st_avct as avct FROM " ~ source('gracethd', 't_site'),
        condition      = "src.statut = 'REC' AND (src.avct = 'E' OR src.avct = 'S') AND (src.attribut IS NULL)"
    )
}}
