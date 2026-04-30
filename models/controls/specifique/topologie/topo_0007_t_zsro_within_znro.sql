{{ ctrl_specifique(
    id_test='topo_0007',
    type_controle='topologie',
    classe='t_zsro',
    cle_primaire='zs_code',
    attribut='geom',
    description='ZSRO non contenue dans ZNRO',
    requ_princ="SELECT "
                ~ "    zs.zs_code, "
                ~ "    ST_Within(zs.geom, ST_Buffer(zn.geom, 100)) AS is_within "
                ~ "FROM " ~ source('gracethd', 't_zsro') ~ " zs "
                ~ "LEFT JOIN " ~ source('gracethd', 't_znro') ~ " zn ON zs.zs_zn_code = zn.zn_code",
    condition="src.is_within = false OR src.is_within IS NULL",
    detail_erreur="'ZSRO ' || src.zs_code || ' non contenue dans ZNRO'",
    is_active=get_topo_config('topo_0007')
) }}
