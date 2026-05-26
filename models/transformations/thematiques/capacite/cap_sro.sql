{{
    config(
        materialized = 'table',
        schema = 'transformations',
        tags = ['grace_thematiques', 'grace_capacite'],
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['lc_code'], 'type': 'btree'}
        ]
    )
}}

WITH fo_tr_par_lc AS (
    SELECT
        lc_code,
        COUNT(*) AS nb_fo_transport
    FROM {{ ref('ropt_section') }}
    WHERE ropt_typelog IN ('TR', 'CT')
      AND lc_code IS NOT NULL
    GROUP BY lc_code
)

SELECT
    lc.id,
    lc.lc_code,
    lc.lc_bp_codf,
    lc.lc_bp_codp,
    lc.lc_codeext,
    lc.lc_abandon,
    lc.lc_prop,
    lc.lc_gest,
    lc.lc_statut,
    lc.lc_dateins,
    lc.lc_elec,
    lc.lc_bat,
    lc.lc_escal,
    lc.lc_etage,
    lc.lc_avct,
    lc.lc_perirec,
    lc.lc_etiquet,
    lc.lc_st_code,
    lc.lc_typelog,
    lc.lc_proptyp,
    COALESCE(fo.nb_fo_transport, 0) AS nb_fo_transport,
    lc.geom
FROM {{ ref('elem_lc_st_nd') }} lc
LEFT JOIN fo_tr_par_lc fo ON fo.lc_code = lc.lc_code
WHERE lc.lc_typelog = 'SRO'
