{{ ctrl_specifique(
    id_test='topo_0001',
    type_controle='topologie',
    classe='t_cheminement',
    cle_primaire='cm_code',
    attribut='cm_ndcode1',
    description='Distance cm_ndcode1/extr cheminement > 0.01m',
    requ_princ="SELECT "
                ~ "    cm.cm_code, "
                ~ "    cm.cm_ndcode1, "
                ~ "    nd.geom AS nd_geom, "
                ~ "    ROUND(CAST(LEAST(ST_Distance(ST_StartPoint(ST_LineMerge(cm.geom)), nd.geom), "
                ~ "                 ST_Distance(ST_EndPoint(ST_LineMerge(cm.geom)), nd.geom)) AS numeric), 3) AS distance "
                ~ "FROM " ~ source('gracethd', 't_cheminement') ~ " cm "
                ~ "LEFT JOIN " ~ source('gracethd', 't_noeud') ~ " nd ON nd.nd_code = cm.cm_ndcode1",
    condition="src.distance > 0.01",
    detail_erreur="'Distance constatée : ' || src.distance || ' m'",
    is_active=get_topo_config('topo_0001')
) }}
