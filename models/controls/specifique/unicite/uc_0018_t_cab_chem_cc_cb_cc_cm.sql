-- Contrôle d'unicité spécifique sur clé composite (cc_cb_code, cc_cm_code)
-- Legacy: Doublon sur le couple (cc_cb_code, cc_cm_code) dans t_cab_chem

{{ ctrl_specifique(
    id_test='ctrl_uc_0018',
    type_controle='unicite',
    classe='t_cab_chem',
    cle_primaire='cc_id',
    attribut='cc_cb_code,cc_cm_code',
    description='Doublon sur le couple (cc_cb_code, cc_cm_code) dans t_cab_chem',
    requ_princ="SELECT "
                ~ "    t_cab_chem.cc_cb_code || ',' || t_cab_chem.cc_cm_code as cc_id, "
                ~ "    t_cab_chem.cc_cb_code, "
                ~ "    t_cab_chem.cc_cm_code, "
                ~ "    doublons.nb_occ "
                ~ "FROM " ~ source('gracethd', 't_cab_chem') ~ " "
                ~ "JOIN ( "
                ~ "    SELECT "
                ~ "        cc_cb_code, "
                ~ "        cc_cm_code, "
                ~ "        COUNT(*) as nb_occ "
                ~ "    FROM " ~ source('gracethd', 't_cab_chem') ~ " "
                ~ "    WHERE cc_cb_code IS NOT NULL AND cc_cb_code != '' "
                ~ "      AND cc_cm_code IS NOT NULL AND cc_cm_code != '' "
                ~ "    GROUP BY cc_cb_code, cc_cm_code "
                ~ "    HAVING COUNT(*) > 1 "
                ~ ") doublons ON doublons.cc_cb_code = t_cab_chem.cc_cb_code AND doublons.cc_cm_code = t_cab_chem.cc_cm_code",
    condition="src.nb_occ > 1",
    detail_erreur="'Valeur : ' || src.cc_cb_code || ' x ' || src.cc_cm_code || ' / nb occurrences : ' || CAST(src.nb_occ AS text)",
    is_active=true
) }}
