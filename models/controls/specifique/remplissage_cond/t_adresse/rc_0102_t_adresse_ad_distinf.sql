{{ config(materialized='table', tags=['grace_control']) }}

{{
    ctrl_specifique(
        id_test        = 'ctrl_rc_0102',
        type_controle  = 'remplissage_conditionnel',
        classe         = 't_adresse',
        cle_primaire   = 'ad_code',
        attribut       = 'ad_distinf',
        description    = "Le champ [ad_distinf] est vide alors que le PB n'est pas dans l'immeuble",
        requ_princ     = "SELECT DISTINCT ad_code, ad_distinf, bp_lc_code, bp_pt_code FROM " ~ source('gracethd', 't_adresse') ~ " LEFT JOIN " ~ source('gracethd', 't_site') ~ " on st_ad_code = ad_code LEFT JOIN " ~ source('gracethd', 't_local') ~ " on (lc_st_code = st_code and lc_typelog = 'RES') LEFT JOIN " ~ source('gracethd', 't_ebp') ~ " ON lc_bp_codf = bp_code",
        condition      = "(src.ad_distinf IS NULL OR trim(src.ad_distinf::text) = '') AND src.bp_pt_code IS NOT NULL",
        is_active      = get_rc_config('ctrl_rc_0102')
    )
}}
