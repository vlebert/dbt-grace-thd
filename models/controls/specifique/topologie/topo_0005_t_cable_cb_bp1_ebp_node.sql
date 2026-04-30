{{ ctrl_specifique(
    id_test='topo_0005',
    type_controle='topologie',
    classe='t_cable',
    cle_primaire='cb_code',
    attribut='cb_bp1',
    description='cb_bp1 non sur cb_nd1 (via ebp/ptech)',
    requ_princ="SELECT "
                ~ "    cb.cb_code, "
                ~ "    cb.cb_nd1, "
                ~ "    cb.cb_bp1, "
                ~ "    pt.pt_nd_code "
                ~ "FROM " ~ source('gracethd', 't_cable') ~ " cb "
                ~ "INNER JOIN " ~ source('gracethd', 't_ebp') ~ " bp ON cb.cb_bp1 = bp.bp_code "
                ~ "LEFT JOIN " ~ source('gracethd', 't_ptech') ~ " pt ON bp.bp_pt_code = pt.pt_code",
    condition="src.cb_nd1 <> src.pt_nd_code OR src.pt_nd_code IS NULL",
    detail_erreur="'cb_bp1=' || src.cb_bp1 || ' sur node ' || src.cb_nd1 || ' mais ebp sur node ' || COALESCE(src.pt_nd_code, 'NULL')",
    is_active=get_topo_config('topo_0005')
) }}
