{{ ctrl_specifique(
    id_test='topo_0006',
    type_controle='topologie',
    classe='t_cable',
    cle_primaire='cb_code',
    attribut='cb_bp2',
    description="cb_bp2 n'est pas sur cb_nd2 (via ebp/ptech ou local/site)",
    requ_princ="SELECT "
                ~ "    cb.cb_code, "
                ~ "    cb.cb_nd2, "
                ~ "    cb.cb_bp2, "
                ~ "    COALESCE(pt.pt_nd_code, st.st_nd_code) AS ebp_node "
                ~ "FROM " ~ source('gracethd', 't_cable') ~ " cb "
                ~ "INNER JOIN " ~ source('gracethd', 't_ebp') ~ " bp ON cb.cb_bp2 = bp.bp_code "
                ~ "LEFT JOIN " ~ source('gracethd', 't_ptech') ~ " pt ON bp.bp_pt_code = pt.pt_code "
                ~ "LEFT JOIN " ~ source('gracethd', 't_local') ~ " lc ON bp.bp_lc_code = lc.lc_code "
                ~ "LEFT JOIN " ~ source('gracethd', 't_site') ~ " st ON lc.lc_st_code = st.st_code",
    condition="src.cb_nd2 IS DISTINCT FROM src.ebp_node",
    detail_erreur="'cb_bp2=' || src.cb_bp2 || ' sur node ' || src.cb_nd2 || ' mais ebp sur node ' || COALESCE(src.ebp_node, 'NULL')",
    is_active=get_topo_config('topo_0006')
) }}
