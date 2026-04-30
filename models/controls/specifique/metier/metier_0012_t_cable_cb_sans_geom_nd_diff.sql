-- Control: Cable without geometry but with different upstream/downstream nodes
-- Legacy: Cable sans géométrie (t_cableline) mais dont les noeuds amont/aval sont différents

{{ ctrl_specifique(
    id_test='metier_0012',
    type_controle='métier',
    classe='t_cable',
    cle_primaire='cb_code',
    attribut='geom,cb_nd1,cb_nd2',
    description='Cable sans geom mais nd1 != nd2',
    requ_princ="SELECT "
                ~ "    cb.cb_code, "
                ~ "    cb.cb_nd1, "
                ~ "    cb.cb_nd2, "
                ~ "    cl.cl_cb_code "
                ~ "FROM " ~ source('gracethd', 't_cable') ~ " cb "
                ~ "LEFT JOIN " ~ source('gracethd', 't_cableline') ~ " cl ON cb.cb_code = cl.cl_cb_code",
    condition="src.cl_cb_code IS NULL AND src.cb_nd1 IS NOT NULL AND src.cb_nd2 IS NOT NULL AND src.cb_nd1 != src.cb_nd2",
    detail_erreur="'Cable sans geometrie avec noeud amont (' || COALESCE(src.cb_nd1, 'NULL') || ') different du noeud aval (' || COALESCE(src.cb_nd2, 'NULL') || ')'",
    is_active=get_metier_config('metier_0012')
) }}
