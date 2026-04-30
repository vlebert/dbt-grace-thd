{{ ctrl_specifique(
    id_test='topo_0009',
    type_controle='topologie',
    classe='t_cable',
    cle_primaire='cb_code',
    attribut='cb_ba2',
    description='cb_ba2 ne correspond pas à une baie située sur le noeud cb_nd2',
    requ_princ="SELECT "
                ~ "    cb.cb_code, "
                ~ "    cb.cb_nd2, "
                ~ "    cb.cb_ba2, "
                ~ "    st.st_nd_code "
                ~ "FROM " ~ source('gracethd', 't_cable') ~ " cb "
                ~ "INNER JOIN " ~ source('gracethd', 't_baie') ~ " ba ON cb.cb_ba2 = ba.ba_code "
                ~ "INNER JOIN " ~ source('gracethd', 't_local') ~ " lc ON ba.ba_lc_code = lc.lc_code "
                ~ "INNER JOIN " ~ source('gracethd', 't_site') ~ " st ON lc.lc_st_code = st.st_code "
                ~ "WHERE cb.cb_ba2 IS NOT NULL",
    condition="src.cb_nd2 <> src.st_nd_code OR src.st_nd_code IS NULL",
    detail_erreur="'Noeud câble (cb_nd2): ' || src.cb_nd2 || ' / Noeud site baie: ' || COALESCE(src.st_nd_code, 'NULL')",
    is_active=get_topo_config('topo_0009')
) }}
