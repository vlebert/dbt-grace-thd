-- Control: NRO local not associated with NRO zone
-- Legacy: Local de type NRO non associé à une zone NRO

{{ ctrl_specifique(
    id_test='metier_0016',
    type_controle='métier',
    classe='t_local',
    cle_primaire='lc_code',
    attribut='lc_code',
    description='NRO non associe a zone NRO',
    requ_princ="SELECT "
                ~ "    lc.lc_code, "
                ~ "    lc.lc_codeext, "
                ~ "    lc.lc_typelog, "
                ~ "    zn.zn_code "
                ~ "FROM " ~ source('gracethd', 't_local') ~ " lc "
                ~ "LEFT JOIN " ~ source('gracethd', 't_znro') ~ " zn ON lc.lc_code = zn.zn_lc_code "
                ~ "WHERE lc.lc_typelog = 'NRO'",
    condition="src.zn_code IS NULL",
    detail_erreur="'Local de type NRO non associe a zone NRO - Type: ' || COALESCE(src.lc_typelog, 'NULL') || ' - Code externe: ' || COALESCE(src.lc_codeext, 'NULL')",
    is_active=get_metier_config('metier_0016')
) }}
