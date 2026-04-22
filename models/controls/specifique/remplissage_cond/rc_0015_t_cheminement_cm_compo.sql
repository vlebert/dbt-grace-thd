{{ config(materialized='table', tags=['control']) }}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0015',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_cheminement',
        cle_primaire = 'cm_code',
        attribut     = 'cm_compo',
        description  = "Le champ [cm_compo] est vide alors que le tronçon de cheminement est de type GC à construire",
        requ_princ   = "SELECT cm_code, cm_compo, cm_avct, or_nom FROM " ~ source('gracethd', 't_cheminement') ~ " LEFT JOIN " ~ source('gracethd', 't_organisme') ~ " ON cm_prop = or_code",
        condition    = "src.cm_compo IS NULL AND (src.cm_avct = 'C' OR src.or_nom = 'ORANGE')",
        detail_erreur = "'cm_avct = ' || src.cm_avct ||' / or_nom = ' || src.or_nom"
    )
}}
