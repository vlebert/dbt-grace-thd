-- Control: Cable with cb_typelog = 'NC'
-- Legacy: Le champ cb_typelog de t_cable a la valeur NC (Non Communiqué)

{{ ctrl_specifique(
    id_test='metier_0007',
    type_controle='métier',
    classe='t_cable',
    cle_primaire='cb_code',
    attribut='cb_typelog',
    description='Cable cb_typelog = NC',
    requ_princ="SELECT "
                ~ "    cb_code, "
                ~ "    cb_typelog "
                ~ "FROM " ~ source('gracethd', 't_cable'),
    condition="src.cb_typelog = 'NC'",
    detail_erreur="'Pas de detail pour cette erreur'",
    is_active=get_metier_config('metier_0007')
) }}
