-- Control: Multiple NRO locals on the same node
-- Legacy: Plusieurs locaux de type NRO sur un même nœud

{{ ctrl_specifique(
    id_test='metier_0015',
    type_controle='métier',
    classe='t_local',
    cle_primaire='lc_code',
    attribut='lc_st_code',
    description='Plusieurs NRO sur meme noeud',
    requ_princ="SELECT "
                ~ "    lc1.lc_code, "
                ~ "    lc1.lc_codeext, "
                ~ "    lc1.lc_st_code, "
                ~ "    st1.st_nd_code, "
                ~ "    STRING_AGG(lc2.lc_code || '(' || COALESCE(lc2.lc_codeext, 'NULL') || ')', ', ') AS autres_nro_meme_noeud, "
                ~ "    COUNT(lc2.lc_code) AS nb_autres_nro "
                ~ "FROM " ~ source('gracethd', 't_local') ~ " lc1 "
                ~ "LEFT JOIN " ~ source('gracethd', 't_site') ~ " st1 ON lc1.lc_st_code = st1.st_code "
                ~ "LEFT JOIN " ~ source('gracethd', 't_site') ~ " st2 ON st1.st_nd_code = st2.st_nd_code "
                ~ "LEFT JOIN " ~ source('gracethd', 't_local') ~ " lc2 ON st2.st_code = lc2.lc_st_code "
                ~ "WHERE lc1.lc_typelog = 'NRO' "
                ~ "  AND lc2.lc_typelog = 'NRO' "
                ~ "  AND lc1.lc_code != lc2.lc_code "
                ~ "GROUP BY lc1.lc_code, lc1.lc_codeext, lc1.lc_st_code, st1.st_nd_code",
    condition="src.nb_autres_nro > 0",
    detail_erreur="'NRO : ' || src.lc_code || '(' || COALESCE(src.lc_codeext, 'NULL') || ') / Noeud : ' || COALESCE(src.st_nd_code, 'NULL') || ' / Autres NRO sur le meme noeud : ' || src.autres_nro_meme_noeud",
    is_active=get_metier_config('metier_0015')
) }}
