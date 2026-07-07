{{ ctrl_specifique(
    id_test='topo_0012',
    type_controle='topologie',
    classe='t_cable',
    cle_primaire='cb_code',
    attribut='cb_code',
    description='Ecart > 10 pour cent long cable/somme cheminements',
    requ_princ="WITH cable_len AS ( "
                ~ "    SELECT "
                ~ "        cl.cl_cb_code AS cb_code, "
                ~ "        SUM(ST_Length(cl.geom)) AS longueur_cable "
                ~ "    FROM " ~ source('gracethd', 't_cableline') ~ " cl "
                ~ "    GROUP BY cl.cl_cb_code "
                ~ "), "
                ~ "chem_agg AS ( "
                ~ "    SELECT "
                ~ "        cc.cc_cb_code AS cb_code, "
                ~ "        SUM(ST_Length(cm.geom)) AS somme_longueur_cheminements, "
                ~ "        COUNT(*) AS nb_cheminements, "
                ~ "        STRING_AGG(cm.cm_code, ', ') AS liste_cm_codes "
                ~ "    FROM " ~ source('gracethd', 't_cab_chem') ~ " cc "
                ~ "    JOIN " ~ source('gracethd', 't_cheminement') ~ " cm ON cc.cc_cm_code = cm.cm_code "
                ~ "    GROUP BY cc.cc_cb_code "
                ~ ") "
                ~ "SELECT "
                ~ "    cbl.cb_code, "
                ~ "    cb.cb_codeext, "
                ~ "    cbl.longueur_cable, "
                ~ "    COALESCE(ca.somme_longueur_cheminements, 0) AS somme_longueur_cheminements, "
                ~ "    COALESCE(ca.nb_cheminements, 0) AS nb_cheminements, "
                ~ "    ca.liste_cm_codes "
                ~ "FROM cable_len cbl "
                ~ "LEFT JOIN " ~ source('gracethd', 't_cable') ~ " cb ON cbl.cb_code = cb.cb_code "
                ~ "LEFT JOIN chem_agg ca ON cbl.cb_code = ca.cb_code",
    condition="src.longueur_cable IS NOT NULL "
             ~ "AND src.longueur_cable > 0 "
             ~ "AND src.somme_longueur_cheminements > 0 "
             ~ "AND ABS(src.longueur_cable - src.somme_longueur_cheminements) > (src.longueur_cable * 0.1)",
    detail_erreur="'Cable: ' || COALESCE(src.cb_codeext, 'N/A') || 
                 ' / Longueur: ' || ROUND(CAST(src.longueur_cable AS numeric), 2) || 
                 ' / Somme cheminements: ' || ROUND(CAST(src.somme_longueur_cheminements AS numeric), 2) || 
                 ' / Ecart: ' || ROUND(CAST(ABS(src.longueur_cable - src.somme_longueur_cheminements) AS numeric), 2) || 
                 ' (' || ROUND(CAST((ABS(src.longueur_cable - src.somme_longueur_cheminements) / src.longueur_cable * 100) AS numeric), 1) || ' pourcent) / Cheminements: ' || 
                 COALESCE(src.liste_cm_codes, 'Aucun')",
    is_active=get_topo_config('topo_0012')
) }}
