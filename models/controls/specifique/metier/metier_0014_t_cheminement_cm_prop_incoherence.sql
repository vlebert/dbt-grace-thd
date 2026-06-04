-- Control: Inconsistency of owner between cheminement and chambers
-- Legacy: Incohérence sur les attributs liés : propriétaire cheminement vs chambres

{{ ctrl_specifique(
    id_test='metier_0014',
    type_controle='métier',
    classe='t_cheminement',
    cle_primaire='cm_code',
    attribut='cm_prop',
    description='Incoherence propriétaire cheminement et chambres aux extrémités',
    requ_princ="SELECT "
                ~ "    cm.cm_code, "
                ~ "    cm.cm_prop AS cm_prop_code, "
                ~ "    org_cm.or_nom AS cm_prop_nom, "
                ~ "    pt1.pt_prop AS pt1_prop_code, "
                ~ "    org_pt1.or_nom AS pt1_prop_nom "
                ~ "FROM " ~ source('gracethd', 't_cheminement') ~ " cm "
                ~ "JOIN " ~ source('gracethd', 't_noeud') ~ " nd1 ON cm.cm_ndcode1 = nd1.nd_code "
                ~ "JOIN " ~ source('gracethd', 't_noeud') ~ " nd2 ON cm.cm_ndcode2 = nd2.nd_code "
                ~ "JOIN " ~ source('gracethd', 't_ptech') ~ " pt1 ON nd1.nd_code = pt1.pt_nd_code "
                ~ "JOIN " ~ source('gracethd', 't_ptech') ~ " pt2 ON nd2.nd_code = pt2.pt_nd_code "
                ~ "LEFT JOIN " ~ source('gracethd', 't_organisme') ~ " org_cm ON cm.cm_prop = org_cm.or_code "
                ~ "LEFT JOIN " ~ source('gracethd', 't_organisme') ~ " org_pt1 ON pt1.pt_prop = org_pt1.or_code "
                ~ "WHERE pt1.pt_prop IS NOT NULL "
                ~ "  AND pt2.pt_prop IS NOT NULL "
                ~ "  AND pt1.pt_prop = pt2.pt_prop",
    condition="src.cm_prop_code IS NULL OR src.cm_prop_code != src.pt1_prop_code",
    detail_erreur="'Proprietaire du cheminement: ' || COALESCE(src.cm_prop_nom, 'Non defini') || ' (' || COALESCE(src.cm_prop_code, 'Non defini') || ') != Proprietaire des chambres: ' || COALESCE(src.pt1_prop_nom, 'Non defini') || ' (' || COALESCE(src.pt1_prop_code, 'Non defini') || ')'",
    is_active=get_metier_config('metier_0014')
) }}
