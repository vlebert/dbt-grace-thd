{{ ctrl_specifique(
    id_test='topo_0010',
    type_controle='topologie',
    classe='t_cable',
    cle_primaire='cb_code',
    attribut='cb_nd1',
    description="Absence de cheminement de départ pour câble (hors RACCORDEMENT)",
    requ_princ="SELECT "
                ~ "    cb.cb_code, "
                ~ "    cb.cb_nd1, "
                ~ "    EXISTS ( "
                ~ "        SELECT 1 "
                ~ "        FROM " ~ source('gracethd', 't_cheminement') ~ " cm "
                ~ "        WHERE cm.cm_ndcode1 = cb.cb_nd1 OR cm.cm_ndcode2 = cb.cb_nd1 "
                ~ "    ) AS has_cheminement "
                ~ "FROM " ~ source('gracethd', 't_cable') ~ " cb "
                ~ "WHERE cb.cb_typelog != 'RA'",
    condition="src.has_cheminement = false",
    detail_erreur="'Pas de cheminement de départ pour câble ' || src.cb_code || ' (nd1: ' || src.cb_nd1 || ')'",
    is_active=get_topo_config('topo_0010')
) }}
