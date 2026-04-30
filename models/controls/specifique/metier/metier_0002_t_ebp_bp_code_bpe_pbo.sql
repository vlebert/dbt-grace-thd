-- Control: EBP (BPE, PBO) not referenced downstream of a cable
-- Legacy: Le t_ebp (BPE, PBO) n'est pas référencé en aval d'un câble (cb_bp2)

{{ ctrl_specifique(
    id_test='metier_0002',
    type_controle='métier',
    classe='t_ebp',
    cle_primaire='bp_code',
    attribut='bp_code',
    description='EBP BPE/PBO non reference en aval',
    requ_princ="SELECT "
                ~ "    e.bp_code, "
                ~ "    e.bp_typelog, "
                ~ "    c.cb_bp2 "
                ~ "FROM " ~ source('gracethd', 't_ebp') ~ " e "
                ~ "LEFT JOIN " ~ source('gracethd', 't_cable') ~ " c ON c.cb_bp2 = e.bp_code "
                ~ "WHERE e.bp_typelog IN ('BPE', 'PBO')",
    condition="src.cb_bp2 IS NULL",
    detail_erreur="'Pas de detail pour cette erreur'",
    is_active=get_metier_config('metier_0002')
) }}
