{{ ctrl_specifique(
    id_test='metier_0020',
    type_controle='métier',
    classe='t_zsro',
    cle_primaire='zs_code',
    attribut='zs_lc_code',
    description='Local technique associé à plusieurs ZSRO',
    requ_princ="SELECT "
               ~ "    zs.zs_code, "
               ~ "    zs.zs_lc_code, "
               ~ "    lc.lc_codeext, "
               ~ "    lc.lc_typelog, "
               ~ "    COUNT(*) OVER (PARTITION BY zs.zs_lc_code) AS nb_zsro, "
               ~ "    STRING_AGG(zs.zs_code, ', ') OVER (PARTITION BY zs.zs_lc_code) AS zsro_meme_lc "
               ~ "FROM " ~ source('gracethd', 't_zsro') ~ " zs "
               ~ "LEFT JOIN " ~ source('gracethd', 't_local') ~ " lc ON lc.lc_code = zs.zs_lc_code "
               ~ "WHERE zs.zs_lc_code IS NOT NULL",
    condition="src.nb_zsro > 1",
    detail_erreur="'zs_lc_code: ' || src.zs_lc_code"
               ~ " || ' / lc_codeext: ' || COALESCE(src.lc_codeext, 'NULL')"
               ~ " || ' / lc_typelog: ' || COALESCE(src.lc_typelog, 'NULL')"
               ~ " || ' / ZSRO partageant ce LC (' || src.nb_zsro || '): ' || src.zsro_meme_lc",
    is_active=get_metier_config('metier_0020')
) }}
