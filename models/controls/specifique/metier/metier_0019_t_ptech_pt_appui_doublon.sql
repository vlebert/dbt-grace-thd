-- Control: Potential support duplicate: same FT identifier and distance < 50m
-- Legacy: Doublon potentiel d'appui : même identifiant FT et distance < 50m

{{ ctrl_specifique(
    id_test='metier_0019',
    type_controle='métier',
    classe='t_ptech',
    cle_primaire='pt_code',
    attribut='pt_codeext',
    description='Doublon appui FT <50m',
    requ_princ="WITH ptech_ft AS ( "
                ~ "    SELECT "
                ~ "        pt_code, "
                ~ "        pt_codeext, "
                ~ "        pt_nd_code, "
                ~ "        SUBSTRING(pt_codeext FROM POSITION('-FT-' IN pt_codeext) + 4) AS nom_appui "
                ~ "    FROM " ~ source('gracethd', 't_ptech') ~ " "
                ~ "    WHERE pt_codeext LIKE '%-FT-%' "
                ~ ") "
                ~ "SELECT "
                ~ "    p1.pt_code, "
                ~ "    p1.pt_codeext, "
                ~ "    p1.nom_appui, "
                ~ "    p2.pt_codeext AS codeext_doublon, "
                ~ "    ROUND(CAST(ST_Distance(n1.geom, n2.geom) AS numeric), 2) AS distance_m "
                ~ "FROM ptech_ft p1 "
                ~ "JOIN ptech_ft p2 "
                ~ "  ON p1.nom_appui = p2.nom_appui "
                ~ "  AND p1.pt_code < p2.pt_code "
                ~ "JOIN " ~ source('gracethd', 't_noeud') ~ " n1 ON p1.pt_nd_code = n1.nd_code "
                ~ "JOIN " ~ source('gracethd', 't_noeud') ~ " n2 ON p2.pt_nd_code = n2.nd_code",
    condition="src.distance_m < 50",
    detail_erreur="'Nom appui : ' || COALESCE(src.nom_appui, '') || ' / Doublon : ' || COALESCE(src.codeext_doublon, '') || ' / Distance : ' || COALESCE(CAST(src.distance_m AS text), '') || ' m'",
    is_active=get_metier_config('metier_0019')
) }}
