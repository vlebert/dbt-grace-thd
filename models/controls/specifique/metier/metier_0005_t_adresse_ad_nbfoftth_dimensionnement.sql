-- Control: Inconsistency in dimensioning attributes (ad_nbfoftth)
-- Legacy: Incohérence sur les attributs liés au dimensionnement : ad_nbfoftth <> ad_nblres + ad_nblpro + ad_nblent + ad_nblpub

{{ ctrl_specifique(
    id_test='metier_0005',
    type_controle='métier',
    classe='t_adresse',
    cle_primaire='ad_code',
    attribut='ad_nbfoftth',
    description='Incoherence ad_nbfoftth vs somme',
    requ_princ="SELECT "
                ~ "    a.ad_code, "
                ~ "    a.ad_nbfotth, "
                ~ "    a.ad_nblres, "
                ~ "    a.ad_nblpro, "
                ~ "    a.ad_nblent, "
                ~ "    a.ad_nblpub, "
                ~ "    a.ad_nblres + a.ad_nblpro + a.ad_nblent + a.ad_nblpub as nb_ftth_calc "
                ~ "FROM " ~ source('gracethd', 't_adresse') ~ " a",
    condition="src.ad_nbfotth IS DISTINCT FROM src.nb_ftth_calc",
    detail_erreur="'(ad_nbfotth: ' || COALESCE(CAST(src.ad_nbfotth AS text), 'NULL') || ' / ad_nblres + ad_nblpro + ad_nblent + ad_nblpub = ' || COALESCE(CAST(src.nb_ftth_calc AS text), 'NULL') || ')'",
    is_active=get_metier_config('metier_0005')
) }}
