-- Control: Distribution cable without geometry
-- Legacy: Le câble de distribution n'a pas de géometrie

{{ ctrl_specifique(
    id_test='metier_0003',
    type_controle='métier',
    classe='t_cable',
    cle_primaire='cb_code',
    attribut='cb_code',
    description="Cable distribution sans geometrie alors que l'origine et la destination sont différentes",
    requ_princ="SELECT "
                ~ "    cb.cb_code, "
                ~ "    cb.cb_bp1, "
                ~ "    COALESCE(bp1.bp_pt_code, bp1.bp_lc_code) as amont, "
                ~ "    cb.cb_bp2, "
                ~ "    COALESCE(bp2.bp_pt_code, bp2.bp_lc_code) as aval, "
                ~ "    cb.cb_lgreel, "
                ~ "    cl.cl_code "
                ~ "FROM " ~ source('gracethd', 't_cable') ~ " cb "
                ~ "LEFT JOIN " ~ source('gracethd', 't_cableline') ~ " cl ON cl.cl_cb_code = cb.cb_code "
                ~ "LEFT JOIN " ~ source('gracethd', 't_ebp') ~ " bp1 ON cb.cb_bp1 = bp1.bp_code "
                ~ "LEFT JOIN " ~ source('gracethd', 't_ebp') ~ " bp2 ON cb.cb_bp2 = bp2.bp_code "
                ~ "WHERE cb.cb_typelog = 'DI'",
    condition="src.cl_code IS NULL AND src.amont IS DISTINCT FROM src.aval",
    detail_erreur="'cb_bp1 : ' || COALESCE(src.cb_bp1, '') || ' (' || COALESCE(src.amont, '') || ') cb_bp2 : ' || COALESCE(src.cb_bp2, '') || ' (' || COALESCE(src.aval, '') || ') / cb_lgreel : ' || COALESCE(CAST(src.cb_lgreel AS text), '')",
    is_active=get_metier_config('metier_0003')
) }}
