{{ ctrl_specifique(
    id_test='topo_0012',
    type_controle='topologie',
    classe='t_cable',
    cle_primaire='cb_code',
    attribut='cb_code',
    description="Écart > 10% entre longueur câble et somme des longueurs des cheminements associés",
    requ_princ="SELECT "
                ~ "    cl.cl_cb_code AS cb_code, "
                ~ "    cb.cb_codeext, "
                ~ "    ST_Length(cl.geom) AS longueur_cable, "
                ~ "    COALESCE(SUM(ST_Length(cm.geom)), 0) AS somme_longueur_cheminements, "
                ~ "    COUNT(cc.cc_cm_code) AS nb_cheminements, "
                ~ "    STRING_AGG(cm.cm_code, ', ') AS liste_cm_codes "
                ~ "FROM " ~ source('gracethd', 't_cableline') ~ " cl "
                ~ "LEFT JOIN " ~ source('gracethd', 't_cable') ~ " cb ON cl.cl_cb_code = cb.cb_code "
                ~ "LEFT JOIN " ~ source('gracethd', 't_cab_chem') ~ " cc ON cl.cl_cb_code = cc.cc_cb_code "
                ~ "LEFT JOIN " ~ source('gracethd', 't_cheminement') ~ " cm ON cc.cc_cm_code = cm.cm_code "
                ~ "GROUP BY cl.cl_cb_code, cb.cb_codeext, cl.geom",
    condition="src.longueur_cable IS NOT NULL "
             ~ "AND src.longueur_cable > 0 "
             ~ "AND src.somme_longueur_cheminements > 0 "
             ~ "AND ABS(src.longueur_cable - src.somme_longueur_cheminements) > (src.longueur_cable * 0.1)",
    detail_erreur="'Câble: ' || COALESCE(src.cb_codeext, 'N/A') || 
                 ' / Longueur: ' || ROUND(src.longueur_cable, 2) || 
                 ' / Somme cheminements: ' || ROUND(src.somme_longueur_cheminements, 2) || 
                 ' / Écart: ' || ROUND(ABS(src.longueur_cable - src.somme_longueur_cheminements), 2) || 
                 ' (' || ROUND((ABS(src.longueur_cable - src.somme_longueur_cheminements) / src.longueur_cable * 100), 1) || '%) / Cheminements: ' || 
                 COALESCE(src.liste_cm_codes, 'Aucun')",
    is_active=get_topo_config('topo_0012')
) }}
