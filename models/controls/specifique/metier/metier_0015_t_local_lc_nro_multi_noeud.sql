-- Control: Multiple NRO locals on the same node
-- Legacy: Plusieurs locaux de type NRO sur un même nœud

{{ ctrl_specifique(
    id_test='metier_0015',
    type_controle='métier',
    classe='t_local',
    cle_primaire='lc_code',
    attribut='lc_st_code',
    description='Plusieurs NRO sur meme noeud',
    requ_princ="WITH nro_noeuds AS ( "
                ~ "    SELECT "
                ~ "        lc.lc_code, "
                ~ "        lc.lc_codeext, "
                ~ "        s.st_nd_code, "
                ~ "        lc.lc_st_code "
                ~ "    FROM " ~ source('gracethd', 't_local') ~ " lc "
                ~ "    JOIN " ~ source('gracethd', 't_site') ~ " s ON lc.lc_st_code = s.st_code "
                ~ "    WHERE lc.lc_typelog = 'NRO' "
                ~ ") "
                ~ "SELECT "
                ~ "    n1.lc_code, "
                ~ "    n1.lc_codeext, "
                ~ "    n1.lc_st_code, "
                ~ "    n1.st_nd_code, "
                ~ "    STRING_AGG(n2.lc_code || '(' || COALESCE(n2.lc_codeext, 'NULL') || ')', ', ') AS autres_nro_meme_noeud, "
                ~ "    COUNT(n2.lc_code) AS nb_autres_nro "
                ~ "FROM nro_noeuds n1 "
                ~ "JOIN nro_noeuds n2 ON n1.st_nd_code = n2.st_nd_code AND n1.lc_code != n2.lc_code "
                ~ "GROUP BY n1.lc_code, n1.lc_codeext, n1.lc_st_code, n1.st_nd_code",
    condition="src.nb_autres_nro > 0",
    detail_erreur="'NRO : ' || src.lc_code || '(' || COALESCE(src.lc_codeext, 'NULL') || ') / Noeud : ' || COALESCE(src.st_nd_code, 'NULL') || ' / Autres NRO sur le meme noeud : ' || src.autres_nro_meme_noeud",
    is_active=get_metier_config('metier_0015')
) }}
