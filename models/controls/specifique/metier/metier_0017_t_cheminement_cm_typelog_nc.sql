-- Control: Cheminement with cm_typelog = 'NC'
-- Legacy: Le champ cm_typelog de t_cheminement a la valeur NC

{{ ctrl_specifique(
    id_test='metier_0017',
    type_controle='métier',
    classe='t_cheminement',
    cle_primaire='cm_code',
    attribut='cm_typelog',
    description='Cheminement cm_typelog = NC',
    requ_princ="SELECT "
                ~ "    cm_code, "
                ~ "    cm_typelog "
                ~ "FROM " ~ source('gracethd', 't_cheminement'),
    condition="src.cm_typelog = 'NC'",
    detail_erreur="'Pas de detail pour cette erreur'",
    is_active=get_metier_config('metier_0017')
) }}
