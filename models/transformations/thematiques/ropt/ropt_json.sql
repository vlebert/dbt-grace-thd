-- Fiche JSON par local technique de départ : agrégation des routes optiques
-- déjà construites par `ropt_json_route` (une ligne par ropt_id).
--
-- Matérialisé en vue (cf. dbt_project.yml) : filtrée sur un local technique
-- (`WHERE lc_code = '...'`), PostgreSQL pousse le prédicat sous le GROUP BY
-- — lc_code étant clé de groupement — et n'agrège que les routes de ce local
-- via l'index btree(lc_code) de `ropt_json_route`.
--
-- L'identifiant est repris de `ropt_json_route` via MIN() : une window function
-- (row_number) serait une barrière d'optimisation et forcerait le balayage
-- complet à chaque requête.
SELECT
    MIN(id) AS id,
    lc_code,
    MAX(lc_codeext) AS lc_codeext,
    MAX(lc_etiquet) AS lc_etiquet,
    MAX(lc_typelog) AS lc_typelog,
    MAX(lc_etage)   AS lc_etage,
    jsonb_agg(json_data ORDER BY ropt_id) AS json_data
FROM {{ ref('ropt_json_route') }}
GROUP BY lc_code
