{{
    config(
        indexes = [
                    {'columns': ['ropt_id'], 'type': 'btree'},
                    {'columns': ['ropt_ordr'], 'type': 'btree'}
                ]
    )
}}

SELECT
    ropt.ropt_id,
    ropt.ropt_ordr,
    ropt.ropt_typelog,
    lc_amont.lc_code,
    lc_amont.lc_codeext,
    lc_amont.lc_typelog,
    lc_amont.lc_etage,
    ti_amont.ti_codeext,
    bp_amont.bp_code,
    bp_amont.bp_codeext,
    bp_amont.bp_typelog,
    ps_amont.ps_numero,
    ps_amont.ps_fonct,
    ps_amont.ps_preaff,
    cs_amont.cs_num,
    pt_amont.pt_code,
    pt_amont.pt_codeext,
    pt_amont.pt_typephy,
    pt_amont.pt_nature,
    cb.cb_code,
    cb.cb_codeext,
    cb.cb_typelog,
    cb.cb_lgreel,
    cb.cb_capafo,
    fo.fo_numtub,
    fo.fo_nintub
FROM {{ ref('ropt') }} ropt
LEFT JOIN {{ ref('t_position') }} ps_amont ON ps_amont.ps_code = ropt.ps_amont
LEFT JOIN {{ ref('t_cassette') }} cs_amont ON cs_amont.cs_code = ps_amont.ps_cs_code
LEFT JOIN {{ ref('t_tiroir') }} ti_amont ON ti_amont.ti_code = ps_amont.ps_ti_code
LEFT JOIN {{ ref('t_ebp') }} bp_amont ON cs_amont.cs_bp_code = bp_amont.bp_code
LEFT JOIN {{ ref('t_baie') }} ba_amont ON ba_amont.ba_code = ti_amont.ti_ba_code
LEFT JOIN {{ ref('t_local') }} lc_amont ON lc_amont.lc_code = ba_amont.ba_lc_code OR lc_amont.lc_code = bp_amont.bp_lc_code
LEFT JOIN {{ ref('t_site') }} st_amont ON st_amont.st_code = lc_amont.lc_st_code
LEFT JOIN {{ ref('t_ptech') }} pt_amont ON pt_amont.pt_code = bp_amont.bp_pt_code
LEFT JOIN {{ ref('t_fibre') }} fo ON ropt.fo_code = fo.fo_code
LEFT JOIN {{ ref('t_cable') }} cb ON fo.fo_cb_code = cb.cb_code
