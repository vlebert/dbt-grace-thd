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
--
-- sro_*/nro_* : si le local de départ est un SRO (t_zsro.zs_lc_code), le NRO
-- rattaché est retrouvé via sa zone arrière (zs_zn_code -> t_znro.zn_code ->
-- zn_lc_code). Si le local de départ est lui-même un NRO (t_znro.zn_lc_code),
-- les colonnes sro_* restent NULL et les colonnes nro_* reprennent le local
-- de départ.
WITH local_rattachement AS (
    SELECT
        lc.lc_code,
        CASE WHEN zs.zs_lc_code IS NOT NULL THEN lc.lc_code    END AS sro_lc_code,
        CASE WHEN zs.zs_lc_code IS NOT NULL THEN lc.lc_codeext END AS sro_lc_codeext,
        CASE WHEN zs.zs_lc_code IS NOT NULL THEN lc.lc_etiquet END AS sro_lc_etiquet,
        COALESCE(zn_direct.zn_lc_code, zn_sro.zn_lc_code) AS nro_lc_code,
        CASE
            WHEN zn_direct.zn_lc_code IS NOT NULL THEN lc.lc_codeext
            WHEN zn_sro.zn_lc_code IS NOT NULL THEN lc_nro.lc_codeext
        END AS nro_lc_codeext,
        CASE
            WHEN zn_direct.zn_lc_code IS NOT NULL THEN lc.lc_etiquet
            WHEN zn_sro.zn_lc_code IS NOT NULL THEN lc_nro.lc_etiquet
        END AS nro_lc_etiquet
    FROM {{ ref('t_local') }} lc
    LEFT JOIN {{ ref('t_zsro') }} zs        ON zs.zs_lc_code = lc.lc_code
    LEFT JOIN {{ ref('t_znro') }} zn_direct ON zn_direct.zn_lc_code = lc.lc_code
    LEFT JOIN {{ ref('t_znro') }} zn_sro    ON zn_sro.zn_code = zs.zs_zn_code
    LEFT JOIN {{ ref('t_local') }} lc_nro   ON lc_nro.lc_code = zn_sro.zn_lc_code
)

SELECT
    MIN(r.id) AS id,
    r.lc_code,
    MAX(r.lc_codeext) AS lc_codeext,
    MAX(r.lc_etiquet) AS lc_etiquet,
    MAX(r.lc_typelog) AS lc_typelog,
    MAX(r.lc_etage)   AS lc_etage,
    MAX(n.sro_lc_code)    AS sro_lc_code,
    MAX(n.sro_lc_codeext) AS sro_lc_codeext,
    MAX(n.sro_lc_etiquet) AS sro_lc_etiquet,
    MAX(n.nro_lc_code)    AS nro_lc_code,
    MAX(n.nro_lc_codeext) AS nro_lc_codeext,
    MAX(n.nro_lc_etiquet) AS nro_lc_etiquet,
    jsonb_agg(r.json_data ORDER BY r.ropt_id) AS json_data
FROM {{ ref('ropt_json_route') }} r
LEFT JOIN local_rattachement n ON n.lc_code = r.lc_code
GROUP BY r.lc_code
