-- Control: Duplicate tube/fiber combination in cable
-- Legacy: La combinaison n° de tube / n° de fibre est présente plusieurs fois dans le câble

{{ ctrl_specifique(
    id_test='metier_0001',
    type_controle='métier',
    classe='t_fibre',
    cle_primaire='fo_code',
    attribut='fo_numtub,fo_nintub',
    description='Duplicat num tube/fibre dans cable',
    requ_princ="SELECT "
                ~ "    f.fo_code, "
                ~ "    f.fo_cb_code, "
                ~ "    'T' || f.fo_numtub || ' - F' || f.fo_nintub as id_fo, "
                ~ "    tb.num "
                ~ "FROM " ~ source('gracethd', 't_fibre') ~ " f "
                ~ "JOIN ( "
                ~ "    SELECT fo_cb_code, 'T' || fo_numtub || ' - F' || fo_nintub as id_fo, COUNT(*) as num "
                ~ "    FROM " ~ source('gracethd', 't_fibre') ~ " "
                ~ "    GROUP BY fo_cb_code, id_fo "
                ~ "    HAVING COUNT(*) > 1 "
                ~ ") tb ON tb.id_fo = 'T' || f.fo_numtub || ' - F' || f.fo_nintub AND tb.fo_cb_code = f.fo_cb_code",
    condition="src.num > 1",
    detail_erreur="src.id_fo || ' present ' || CAST(src.num AS text) || ' fois dans le cable ' || src.fo_cb_code",
    is_active=get_metier_config('metier_0001')
) }}
