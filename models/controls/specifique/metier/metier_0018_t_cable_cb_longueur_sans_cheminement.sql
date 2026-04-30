-- Control: Cable with geometric length > 0 without cheminement association (non-raccordement)
-- Legacy: Câble avec longueur géométrique > 0 sans association au cheminement (hors raccordement)

{{ ctrl_specifique(
    id_test='metier_0018',
    type_controle='métier',
    classe='t_cable',
    cle_primaire='cb_code',
    attribut='cb_code',
    description='Cable long>0 sans cheminement',
    requ_princ="SELECT "
                ~ "    cb.cb_code, "
                ~ "    cl.cl_code, "
                ~ "    cl.cl_cb_code, "
                ~ "    ROUND(CAST(ST_Length(cl.geom) AS numeric), 2) AS cl_long, "
                ~ "    cb.cb_codeext, "
                ~ "    cc.cc_cm_code "
                ~ "FROM " ~ source('gracethd', 't_cableline') ~ " cl "
                ~ "LEFT JOIN " ~ source('gracethd', 't_cable') ~ " cb ON cl.cl_cb_code = cb.cb_code "
                ~ "LEFT JOIN " ~ source('gracethd', 't_cab_chem') ~ " cc ON cl.cl_cb_code = cc.cc_cb_code "
                ~ "WHERE cb.cb_typelog != 'RA'",
    condition="src.cc_cm_code IS NULL AND src.cl_long > 0",
    detail_erreur="'Longueur geometrique : ' || COALESCE(CAST(src.cl_long AS text), '0') || ' m / Code externe : ' || COALESCE(src.cb_codeext, 'N/D') || ' / Aucun cheminement associe'",
    is_active=get_metier_config('metier_0018')
) }}
