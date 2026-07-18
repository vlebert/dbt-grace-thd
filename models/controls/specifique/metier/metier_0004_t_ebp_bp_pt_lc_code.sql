-- Control: EBP without technical point or technical local
-- Legacy: Le t_ebp n'a ni point de technique (bp_pt_code), ni local technique (bp_lc_code)

{{ ctrl_specifique(
    id_test='metier_0004',
    type_controle='métier',
    classe='t_ebp',
    cle_primaire='bp_code',
    attribut='bp_pt_code,bp_lc_code',
    description='EBP sans point/local technique',
    requ_princ="SELECT "
                ~ "    bp_code, "
                ~ "    bp_pt_code, "
                ~ "    bp_lc_code "
                ~ "FROM " ~ source('gracethd', 't_ebp'),
    condition="(src.bp_pt_code IS NULL OR trim(src.bp_pt_code::text) = '') AND (src.bp_lc_code IS NULL OR trim(src.bp_lc_code::text) = '')",
    detail_erreur="'Pas de detail pour cette erreur'",
    is_active=get_metier_config('metier_0004')
) }}
