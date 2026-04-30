-- Control: Local and zsro don't respect lc_codeext = zs_r3_code
-- Legacy: Le local et la zsro liée par lc_code = zs_lc_code ne respectent pas lc_codeext = zs_r3_code

{{ ctrl_specifique(
    id_test='metier_0008',
    type_controle='métier',
    classe='t_zsro',
    cle_primaire='zs_code',
    attribut='zs_r3_code',
    description='local/zsro lc_codeext != zs_r3',
    requ_princ="SELECT "
                ~ "    lc.lc_code, "
                ~ "    lc.lc_codeext, "
                ~ "    zs.zs_code, "
                ~ "    zs.zs_r3_code "
                ~ "FROM " ~ source('gracethd', 't_local') ~ " lc, " ~ source('gracethd', 't_zsro') ~ " zs "
                ~ "WHERE lc.lc_code = zs.zs_lc_code",
    condition="src.lc_codeext IS DISTINCT FROM src.zs_r3_code",
    detail_erreur="'La zsro est liée au local ' || src.lc_code || ' mais zs_r3_code (' || COALESCE(src.zs_r3_code, 'NULL') || ') <> lc_codeext (' || COALESCE(src.lc_codeext, 'NULL') || ')'",
    is_active=get_metier_config('metier_0008')
) }}
