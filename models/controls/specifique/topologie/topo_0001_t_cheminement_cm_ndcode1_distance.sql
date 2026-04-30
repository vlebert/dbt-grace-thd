{{ ctrl_specifique(
    id_test='topo_0001',
    type_controle='topologie',
    classe='t_cheminement',
    cle_primaire='cm_code',
    attribut='cm_ndcode1',
    description='Distance supérieure à 0,01m entre cm_ndcode1 et extrémités du cheminement',
    requ_princ="SELECT "
                ~ "    cm.cm_code, "
                ~ "    cm.cm_ndcode1, "
                ~ "    nd.geom AS nd_geom, "
                ~ "    ROUND(MIN(ST_Distance(ST_StartPoint(cm.geom), nd.geom), "
                ~ "                 ST_Distance(ST_EndPoint(cm.geom), nd.geom)), 3) AS distance "
                ~ "FROM " ~ source('gracethd', 't_cheminement') ~ " cm "
                ~ "LEFT JOIN " ~ source('gracethd', 't_noeud') ~ " nd ON nd.nd_code = cm.cm_ndcode1",
    condition="src.distance > 0.01",
    detail_erreur="'Distance constatée : ' || src.distance || ' m'",
    is_active=get_topo_config('topo_0001')
) }}
