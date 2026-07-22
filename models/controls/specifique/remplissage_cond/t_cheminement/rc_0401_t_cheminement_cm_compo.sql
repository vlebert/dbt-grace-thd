{{ config(materialized='table', tags=['grace_control']) }}


{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0401',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_cheminement',
        cle_primaire = 'cm_code',
        attribut     = 'cm_compo',
        description  = "Le champ [cm_compo] est vide alors que le tronçon de cheminement est de type GC à construire ou GC Orange en conduite",
        requ_princ   = "SELECT cm_code, cm_compo, cm_avct, cm_typ_imp, or_nom FROM " ~ source('gracethd', 't_cheminement') ~ " LEFT JOIN " ~ source('gracethd', 't_organisme') ~ " ON cm_prop = or_code",
        condition    = "(src.cm_compo IS NULL OR trim(src.cm_compo::text) = '') AND (src.cm_avct = 'C' OR (src.or_nom = 'ORANGE' AND src.cm_typ_imp = '7'))",
        detail_erreur = "'cm_avct = ' || src.cm_avct ||' / or_nom = ' || src.or_nom || ' / cm_typ_imp = ' || src.cm_typ_imp",
        is_active      = get_rc_config('ctrl_rc_0401')
    )
}}
