-- Schéma des tables sources GRACE THD (gracethd_source).
-- Fichier GÉNÉRÉ par scripts/generate_source_schema.py à partir du seed
-- seeds/controls/param_ctrl_remplissage.csv — NE PAS éditer à la main.
--
-- Toutes les colonnes sont en `text` (import brut non bloquant) ; `geom` est
-- une géométrie générique. Aucune contrainte, pour ne jamais bloquer l'import.

CREATE SCHEMA IF NOT EXISTS gracethd_source;

DROP TABLE IF EXISTS gracethd_source.t_adresse;
CREATE TABLE gracethd_source.t_adresse (
    ad_batcode text,
    ad_code text,
    ad_codtemp text,
    ad_commune text,
    ad_datmodi text,
    ad_distinf text,
    ad_dta text,
    ad_gest text,
    ad_hexacle text,
    ad_iaccgst text,
    ad_idatsgn text,
    ad_ietat text,
    ad_imneuf text,
    ad_insee text,
    ad_isole text,
    ad_nbfofon text,
    ad_nbfogfu text,
    ad_nbfotte text,
    ad_nbfotth text,
    ad_nbfotto text,
    ad_nblent text,
    ad_nblobj text,
    ad_nblope text,
    ad_nblpro text,
    ad_nblpub text,
    ad_nblres text,
    ad_nombat text,
    ad_nomvoie text,
    ad_numero text,
    ad_postal text,
    ad_prio text,
    ad_racc text,
    ad_raclong text,
    ad_rep text,
    geom geometry
);

DROP TABLE IF EXISTS gracethd_source.t_baie;
CREATE TABLE gracethd_source.t_baie (
    ba_abandon text,
    ba_code text,
    ba_codeext text,
    ba_etiquet text,
    ba_gest text,
    ba_lc_code text,
    ba_nb_u text,
    ba_perirec text,
    ba_prop text,
    ba_proptyp text,
    ba_rf_code text,
    ba_statut text,
    ba_type text
);

DROP TABLE IF EXISTS gracethd_source.t_cab_chem;
CREATE TABLE gracethd_source.t_cab_chem (
    cc_cb_code text,
    cc_cm_code text
);

DROP TABLE IF EXISTS gracethd_source.t_cable;
CREATE TABLE gracethd_source.t_cable (
    cb_abandon text,
    cb_avct text,
    cb_ba1 text,
    cb_ba2 text,
    cb_bp1 text,
    cb_bp2 text,
    cb_cabphy text,
    cb_capafo text,
    cb_code text,
    cb_codeext text,
    cb_dateins text,
    cb_etiquet text,
    cb_fo_disp text,
    cb_fo_type text,
    cb_fo_util text,
    cb_gest text,
    cb_lgreel text,
    cb_modulo text,
    cb_nd1 text,
    cb_nd2 text,
    cb_perirec text,
    cb_prop text,
    cb_proptyp text,
    cb_r1_code text,
    cb_r2_code text,
    cb_r3_code text,
    cb_rf_code text,
    cb_statut text,
    cb_typelog text,
    cb_typephy text
);

DROP TABLE IF EXISTS gracethd_source.t_cableline;
CREATE TABLE gracethd_source.t_cableline (
    cl_cb_code text,
    cl_code text,
    geom geometry
);

DROP TABLE IF EXISTS gracethd_source.t_cassette;
CREATE TABLE gracethd_source.t_cassette (
    cs_bp_code text,
    cs_code text,
    cs_face text,
    cs_num text,
    cs_rf_code text,
    cs_type text
);

DROP TABLE IF EXISTS gracethd_source.t_cheminement;
CREATE TABLE gracethd_source.t_cheminement (
    cm_avct text,
    cm_code text,
    cm_compo text,
    cm_gest text,
    cm_ndcode1 text,
    cm_ndcode2 text,
    cm_perirec text,
    cm_prop text,
    cm_statut text,
    cm_typ_imp text,
    cm_typelog text,
    geom geometry
);

DROP TABLE IF EXISTS gracethd_source.t_ebp;
CREATE TABLE gracethd_source.t_ebp (
    bp_abandon text,
    bp_avct text,
    bp_code text,
    bp_codeext text,
    bp_dateins text,
    bp_etiquet text,
    bp_gest text,
    bp_lc_code text,
    bp_perirec text,
    bp_prop text,
    bp_proptyp text,
    bp_pt_code text,
    bp_rf_code text,
    bp_statut text,
    bp_typelog text,
    bp_typephy text
);

DROP TABLE IF EXISTS gracethd_source.t_fibre;
CREATE TABLE gracethd_source.t_fibre (
    fo_cb_code text,
    fo_code text,
    fo_etat text,
    fo_nincab text,
    fo_nintub text,
    fo_numtub text
);

DROP TABLE IF EXISTS gracethd_source.t_local;
CREATE TABLE gracethd_source.t_local (
    lc_abandon text,
    lc_avct text,
    lc_bat text,
    lc_bp_codf text,
    lc_bp_codp text,
    lc_code text,
    lc_codeext text,
    lc_dateins text,
    lc_elec text,
    lc_escal text,
    lc_etage text,
    lc_etiquet text,
    lc_gest text,
    lc_perirec text,
    lc_prop text,
    lc_proptyp text,
    lc_st_code text,
    lc_statut text,
    lc_typelog text
);

DROP TABLE IF EXISTS gracethd_source.t_love;
CREATE TABLE gracethd_source.t_love (
    lv_cb_code text,
    lv_id text,
    lv_long text,
    lv_nd_code text
);

DROP TABLE IF EXISTS gracethd_source.t_noeud;
CREATE TABLE gracethd_source.t_noeud (
    geom geometry,
    nd_code text
);

DROP TABLE IF EXISTS gracethd_source.t_organisme;
CREATE TABLE gracethd_source.t_organisme (
    or_code text,
    or_commune text,
    or_local text,
    or_nom text,
    or_nomvoie text,
    or_numero text,
    or_postal text,
    or_rep text,
    or_siret text,
    or_type text
);

DROP TABLE IF EXISTS gracethd_source.t_point_leve;
CREATE TABLE gracethd_source.t_point_leve (
    geom geometry,
    pl_charge text,
    pl_code text,
    pl_x text,
    pl_y text,
    pl_z text
);

DROP TABLE IF EXISTS gracethd_source.t_pointaccueil;
CREATE TABLE gracethd_source.t_pointaccueil (
    geom geometry,
    pa_a_haut text,
    pa_a_struc text,
    pa_code text,
    pa_codeext text,
    pa_codtemp text,
    pa_datecon text,
    pa_dtclass text,
    pa_gest text,
    pa_nature text,
    pa_perirec text,
    pa_prop text,
    pa_rotatio text,
    pa_secu text,
    pa_typephy text
);

DROP TABLE IF EXISTS gracethd_source.t_position;
CREATE TABLE gracethd_source.t_position (
    ps_1 text,
    ps_2 text,
    ps_code text,
    ps_cs_code text,
    ps_fonct text,
    ps_numero text,
    ps_preaff text,
    ps_ti_code text,
    ps_type text
);

DROP TABLE IF EXISTS gracethd_source.t_ptech;
CREATE TABLE gracethd_source.t_ptech (
    pt_a_haut text,
    pt_a_struc text,
    pt_abandon text,
    pt_avct text,
    pt_code text,
    pt_codeext text,
    pt_etiquet text,
    pt_gest text,
    pt_nature text,
    pt_nd_code text,
    pt_perirec text,
    pt_prop text,
    pt_proptyp text,
    pt_secu text,
    pt_statut text,
    pt_typephy text
);

DROP TABLE IF EXISTS gracethd_source.t_reference;
CREATE TABLE gracethd_source.t_reference (
    rf_code text,
    rf_design text,
    rf_type text
);

DROP TABLE IF EXISTS gracethd_source.t_site;
CREATE TABLE gracethd_source.t_site (
    st_abandon text,
    st_ad_code text,
    st_avct text,
    st_code text,
    st_codeext text,
    st_commune text,
    st_dateins text,
    st_design text,
    st_gest text,
    st_insee text,
    st_nd_code text,
    st_nombat text,
    st_nomvoie text,
    st_nra text,
    st_numero text,
    st_perirec text,
    st_postal text,
    st_prop text,
    st_proptyp text,
    st_rep text,
    st_statut text,
    st_typelog text,
    st_typephy text
);

DROP TABLE IF EXISTS gracethd_source.t_tiroir;
CREATE TABLE gracethd_source.t_tiroir (
    ti_abandon text,
    ti_ba_code text,
    ti_code text,
    ti_codeext text,
    ti_etiquet text,
    ti_perirec text,
    ti_placemt text,
    ti_prop text,
    ti_rf_code text,
    ti_taille text,
    ti_type text
);

DROP TABLE IF EXISTS gracethd_source.t_tranchee;
CREATE TABLE gracethd_source.t_tranchee (
    geom geometry,
    tr_code text,
    tr_compo text,
    tr_couptyp text,
    tr_dtclass text,
    tr_lgreel text,
    tr_pa1 text,
    tr_pa2 text,
    tr_perirec text
);

DROP TABLE IF EXISTS gracethd_source.t_zdep;
CREATE TABLE gracethd_source.t_zdep (
    geom geometry,
    zd_code text,
    zd_nd_code text,
    zd_r1_code text,
    zd_r2_code text,
    zd_r3_code text,
    zd_r4_code text,
    zd_statut text,
    zd_zs_code text
);

DROP TABLE IF EXISTS gracethd_source.t_znro;
CREATE TABLE gracethd_source.t_znro (
    geom geometry,
    zn_code text,
    zn_etat text,
    zn_lc_code text,
    zn_nd_code text,
    zn_nom text,
    zn_nroref text,
    zn_r1_code text,
    zn_r2_code text
);

DROP TABLE IF EXISTS gracethd_source.t_zsro;
CREATE TABLE gracethd_source.t_zsro (
    geom geometry,
    zs_actif text,
    zs_capamax text,
    zs_code text,
    zs_etatpm text,
    zs_lc_code text,
    zs_lgmaxln text,
    zs_nblogmt text,
    zs_nom text,
    zs_r1_code text,
    zs_r2_code text,
    zs_r3_code text,
    zs_refpm text,
    zs_zn_code text,
    zs_znllong text
);

