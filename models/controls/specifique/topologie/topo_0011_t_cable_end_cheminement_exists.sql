{{ ctrl_specifique(
    id_test='topo_0011',
    type_controle='topologie',
    classe='t_cable',
    cle_primaire='cb_code',
    attribut='cb_nd2',
    description="Absence de cheminement d'arrivée pour câble (hors RACCORDEMENT)",
    requ_princ="SELECT "
                ~ "    cb.cb_code, "
                ~ "    cb.cb_nd2, "
                ~ "    EXISTS ( "
                ~ "        SELECT 1 "
                ~ "        FROM " ~ source('gracethd', 't_cheminement') ~ " cm "
                ~ "        WHERE cm.cm_ndcode1 = cb.cb_nd2 OR cm.cm_ndcode2 = cb.cb_nd2 "
                ~ "    ) AS has_cheminement "
                ~ "FROM " ~ source('gracethd', 't_cable') ~ " cb "
                ~ "WHERE cb.cb_typelog != 'RA'",
    condition="src.has_cheminement = false",
    detail_erreur="'Pas de cheminement d'arrivée pour câble ' || src.cb_code || ' (nd2: ' || src.cb_nd2 || ')'",
    is_active=get_topo_config('topo_0011')
) }}
