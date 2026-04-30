{{ ctrl_specifique(
    id_test='topo_0004',
    type_controle='topologie',
    classe='t_cable',
    cle_primaire='cb_code',
    attribut='cb_nd2',
    description='Distance supérieure à 0,01m entre cb_nd2 et extrémités du câble',
    requ_princ="SELECT "
                ~ "    cb.cb_code, "
                ~ "    cb.cb_nd2, "
                ~ "    nd.geom AS nd_geom, "
                ~ "    ROUND(CAST(LEAST(ST_Distance(ST_StartPoint(cl.geom), nd.geom), "
                ~ "                 ST_Distance(ST_EndPoint(cl.geom), nd.geom)) AS numeric), 6) AS distance "
                ~ "FROM " ~ source('gracethd', 't_cable') ~ " cb "
                ~ "INNER JOIN " ~ source('gracethd', 't_cableline') ~ " cl ON cb.cb_code = cl.cl_cb_code "
                ~ "LEFT JOIN " ~ source('gracethd', 't_noeud') ~ " nd ON nd.nd_code = cb.cb_nd2",
    condition="src.distance > 0.01",
    detail_erreur="'Distance constatée : ' || src.distance || ' m'",
    is_active=get_topo_config('topo_0004')
) }}
