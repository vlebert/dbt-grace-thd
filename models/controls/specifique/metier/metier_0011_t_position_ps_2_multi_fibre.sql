-- Control: Fiber present downstream in multiple positions (ps_2)
-- Legacy: Erreur de route optique : fibre présente en aval dans plusieurs positions (t_position.ps_2)

{{ ctrl_specifique(
    id_test='metier_0011',
    type_controle='métier',
    classe='t_position',
    cle_primaire='ps_code',
    attribut='ps_2',
    description='Fibre référencée plusieurs fois en aval (ps_2). Erreur de fibrage ou inversion de la logique ps_1 / ps_2',
    requ_princ="SELECT "
                ~ "    p.ps_code, "
                ~ "    tb.code_unic, "
                ~ "    tb.nb_occ "
                ~ "FROM " ~ source('gracethd', 't_position') ~ " p "
                ~ "LEFT JOIN ( "
                ~ "    SELECT ps_2 AS code_unic, COUNT(ps_2) AS nb_occ "
                ~ "    FROM " ~ source('gracethd', 't_position') ~ " "
                ~ "    WHERE ps_2 IS NOT NULL AND ps_2 != '' "
                ~ "    GROUP BY ps_2 "
                ~ "    HAVING COUNT(ps_2) > 1 "
                ~ ") tb ON p.ps_2 = tb.code_unic",
    condition="src.nb_occ > 1",
    detail_erreur="' La fibre ' || src.code_unic || ' est presente ' || CAST(src.nb_occ AS text) || ' fois sur t_position.ps_2'",
    is_active=get_metier_config('metier_0011')
) }}
