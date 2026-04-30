-- Control: Address with sockets on multiple ZSRO
-- Legacy: L'adresse comprend des prises et est située sur plusieurs ZSRO

{{ ctrl_specifique(
    id_test='metier_0009',
    type_controle='métier',
    classe='t_adresse',
    cle_primaire='ad_code',
    attribut='ad_code',
    description='Adresse avec prises sur multi ZSRO',
    requ_princ="SELECT "
                ~ "    a.ad_code, "
                ~ "    COUNT(zs.zs_code) AS nb_zone, "
                ~ "    STRING_AGG(zs.zs_code, ', ') AS zs_codes, "
                ~ "    STRING_AGG(zs.zs_refpm, ', ') AS zs_refpms "
                ~ "FROM " ~ source('gracethd', 't_adresse') ~ " a "
                ~ "LEFT JOIN " ~ source('gracethd', 't_zsro') ~ " zs ON a.geom && zs.geom AND ST_Within(a.geom, zs.geom) "
                ~ "GROUP BY a.ad_code",
    condition="src.nb_zone > 1",
    detail_erreur="'L''adresse est présente dans les ZSRO suivantes : ' || src.zs_codes || ' - ' || src.zs_refpms",
    is_active=get_metier_config('metier_0009')
) }}
