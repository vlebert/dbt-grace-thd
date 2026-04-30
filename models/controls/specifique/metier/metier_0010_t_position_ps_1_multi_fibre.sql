-- Control: Fiber present upstream in multiple positions (ps_1)
-- Legacy: Erreur de route optique : fibre présente en amont dans plusieurs positions (t_position.ps_1)

{{ ctrl_specifique(
    id_test='metier_0010',
    type_controle='métier',
    classe='t_position',
    cle_primaire='ps_code',
    attribut='ps_1',
    description='Fibre multi positions ps_1',
    requ_princ="SELECT "
                ~ "    p.ps_code, "
                ~ "    tb.code_unic, "
                ~ "    tb.nb_occ "
                ~ "FROM " ~ source('gracethd', 't_position') ~ " p "
                ~ "LEFT JOIN ( "
                ~ "    SELECT ps_1 AS code_unic, COUNT(ps_1) AS nb_occ "
                ~ "    FROM " ~ source('gracethd', 't_position') ~ " "
                ~ "    WHERE ps_1 IS NOT NULL AND ps_1 != '' "
                ~ "    GROUP BY ps_1 "
                ~ "    HAVING COUNT(ps_1) > 1 "
                ~ ") tb ON p.ps_1 = tb.code_unic",
    condition="src.nb_occ > 1",
    detail_erreur="' La fibre ' || src.code_unic || ' est presente ' || CAST(src.nb_occ AS text) || ' fois sur t_position.ps_1'",
    is_active=get_metier_config('metier_0010')
) }}
