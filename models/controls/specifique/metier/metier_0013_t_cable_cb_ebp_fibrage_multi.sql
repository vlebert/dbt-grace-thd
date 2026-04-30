-- Control: Cable connected to more than 2 EBP via fibrage
-- Legacy: Câble connecté à plus de 2 t_ebp via fibrage

{{ ctrl_specifique(
    id_test='metier_0013',
    type_controle='métier',
    classe='t_cable',
    cle_primaire='cb_code',
    attribut='cb_code',
    description='Cable connecte >2 EBP via fibrage',
    requ_princ="SELECT "
                ~ "    c.cb_code, "
                ~ "    sub.nb_ebp_fibrage, "
                ~ "    sub.liste_ebp "
                ~ "FROM " ~ source('gracethd', 't_cable') ~ " c "
                ~ "JOIN ( "
                ~ "    SELECT "
                ~ "        f.fo_cb_code, "
                ~ "        COUNT(DISTINCT e.bp_code) AS nb_ebp_fibrage, "
                ~ "        STRING_AGG(DISTINCT e.bp_code, ', ') AS liste_ebp "
                ~ "    FROM " ~ source('gracethd', 't_fibre') ~ " f "
                ~ "    JOIN " ~ source('gracethd', 't_position') ~ " p ON p.ps_1 = f.fo_code OR p.ps_2 = f.fo_code "
                ~ "    JOIN " ~ source('gracethd', 't_cassette') ~ " cs ON cs.cs_code = p.ps_cs_code "
                ~ "    JOIN " ~ source('gracethd', 't_ebp') ~ " e ON e.bp_code = cs.cs_bp_code "
                ~ "    GROUP BY f.fo_cb_code "
                ~ "    HAVING COUNT(DISTINCT e.bp_code) > 2 "
                ~ ") sub ON sub.fo_cb_code = c.cb_code",
    condition="src.nb_ebp_fibrage > 2",
    detail_erreur="'Le cable est connecte a ' || CAST(src.nb_ebp_fibrage AS text) || ' t_ebp via fibrage (' || COALESCE(src.liste_ebp, '') || ')'",
    is_active=get_metier_config('metier_0013')
) }}
