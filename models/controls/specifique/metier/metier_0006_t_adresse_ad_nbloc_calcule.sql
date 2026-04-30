-- Control: Inconsistency in number of premises vs calculated
-- Legacy: Incohérence : le nombre de locaux associé à l'adresse est différent du nombre calculé

{{ ctrl_specifique(
    id_test='metier_0006',
    type_controle='métier',
    classe='t_adresse',
    cle_primaire='ad_code',
    attribut='ad_code',
    description='Nb locaux diff calcul ad_nb*',
    requ_princ="SELECT "
                ~ "    a.ad_code, "
                ~ "    a.ad_nblres, "
                ~ "    a.ad_nblpro, "
                ~ "    a.ad_nblent, "
                ~ "    a.ad_nblpub, "
                ~ "    a.ad_nblres + a.ad_nblpro + a.ad_nblent + a.ad_nblpub as nb_ftth_calc, "
                ~ "    COUNT(l.lc_code) AS nb_loc_calc "
                ~ "FROM " ~ source('gracethd', 't_adresse') ~ " a "
                ~ "LEFT JOIN " ~ source('gracethd', 't_site') ~ " s ON s.st_ad_code = a.ad_code "
                ~ "LEFT JOIN " ~ source('gracethd', 't_local') ~ " l ON l.lc_st_code = s.st_code "
                ~ "GROUP BY a.ad_code, a.ad_nblres, a.ad_nblpro, a.ad_nblent, a.ad_nblpub",
    condition="src.nb_loc_calc IS DISTINCT FROM src.nb_ftth_calc",
    detail_erreur="'(nombre de t_local: ' || COALESCE(CAST(src.nb_loc_calc AS text), 'NULL') || ' / ad_nblres + ad_nblpro + ad_nblent + ad_nblpub = ' || COALESCE(CAST(src.nb_ftth_calc AS text), 'NULL') || ')'",
    is_active=get_metier_config('metier_0006')
) }}
