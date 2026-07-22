{{ ctrl_specifique(
    id_test='topo_0013',
    type_controle='topologie',
    classe='t_cableline',
    cle_primaire='cl_code',
    attribut='geom',
    description='Geometrie de cableline invalide (OGC)',
    requ_princ="SELECT "
                ~ "    cl.cl_code, "
                ~ "    cl.cl_cb_code, "
                ~ "    d.valid, "
                ~ "    d.reason, "
                ~ "    d.location "
                ~ "FROM " ~ source('gracethd', 't_cableline') ~ " cl, "
                ~ "     LATERAL ST_IsValidDetail(cl.geom) AS d "
                ~ "WHERE cl.geom IS NOT NULL",
    condition="NOT src.valid",
    detail_erreur="'Cable: ' || COALESCE(src.cl_cb_code, 'N/A') ||
                 ' / Motif: ' || COALESCE(src.reason, 'N/A') ||
                 ' / Localisation: ' || COALESCE(ST_AsText(src.location), 'N/A')",
    is_active=get_topo_config('topo_0013')
) }}
