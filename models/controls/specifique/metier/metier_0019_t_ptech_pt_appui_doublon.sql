-- Control: Potential support duplicate: same FT identifier and distance < 50m
-- Legacy: Doublon potentiel d'appui : même identifiant FT et distance < 50m

{{ ctrl_specifique(
    id_test='metier_0019',
    type_controle='métier',
    classe='t_ptech',
    cle_primaire='pt_code',
    attribut='pt_codeext',
    description='Doublon appui FT <50m',
    requ_princ="SELECT "
                ~ "    p1.pt_code, "
                ~ "    p1.pt_codeext, "
                ~ "    SUBSTRING(p1.pt_codeext FROM POSITION('-FT-' IN p1.pt_codeext) + 4) AS nom_appui, "
                ~ "    p2.pt_codeext AS codeext_doublon, "
                ~ "    ROUND(CAST(ST_Distance(n1.geom, n2.geom) AS numeric), 2) AS distance_m "
                ~ "FROM " ~ source('gracethd', 't_ptech') ~ " p1 "
                ~ "JOIN " ~ source('gracethd', 't_ptech') ~ " p2 "
                ~ "  ON SUBSTRING(p1.pt_codeext FROM POSITION('-FT-' IN p1.pt_codeext) + 4) = SUBSTRING(p2.pt_codeext FROM POSITION('-FT-' IN p2.pt_codeext) + 4) "
                ~ "  AND p1.pt_code < p2.pt_code "
                ~ "JOIN " ~ source('gracethd', 't_noeud') ~ " n1 ON p1.pt_nd_code = n1.nd_code "
                ~ "JOIN " ~ source('gracethd', 't_noeud') ~ " n2 ON p2.pt_nd_code = n2.nd_code "
                ~ "WHERE p1.pt_codeext LIKE '%-FT-%' "
                ~ "  AND p2.pt_codeext LIKE '%-FT-%'",
    condition="src.distance_m < 50",
    detail_erreur="'Nom appui : ' || COALESCE(src.nom_appui, '') || ' / Doublon : ' || COALESCE(src.codeext_doublon, '') || ' / Distance : ' || COALESCE(CAST(src.distance_m AS text), '') || ' m'",
    is_active=get_metier_config('metier_0019')
) }}
