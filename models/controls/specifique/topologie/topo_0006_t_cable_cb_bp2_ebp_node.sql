{{ ctrl_specifique(
    id_test='topo_0006',
    type_controle='topologie',
    classe='t_cable',
    cle_primaire='cb_code',
    attribut='cb_bp2',
    description='cb_bp2 ne correspond pas à un ebp situé sur cb_nd2',
    requ_princ="SELECT "
                ~ "    cb.cb_code, "
                ~ "    cb.cb_nd2, "
                ~ "    cb.cb_bp2, "
                ~ "    pt.pt_nd_code "
                ~ "FROM " ~ source('gracethd', 't_cable') ~ " cb "
                ~ "INNER JOIN " ~ source('gracethd', 't_ebp') ~ " bp ON cb.cb_bp2 = bp.bp_code "
                ~ "LEFT JOIN " ~ source('gracethd', 't_ptech') ~ " pt ON bp.bp_pt_code = pt.pt_code",
    condition="src.cb_nd2 <> src.pt_nd_code OR src.pt_nd_code IS NULL",
    detail_erreur="'cb_bp2=' || src.cb_bp2 || ' sur node ' || src.cb_nd2 || ' mais ebp sur node ' || COALESCE(src.pt_nd_code, 'NULL')",
    is_active=get_topo_config('topo_0006')
) }}
