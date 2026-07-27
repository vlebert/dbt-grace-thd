{#
  AUTO-GÉNÉRÉ par scripts/generate_index_macro.py depuis scripts/gracethd_indexes.sql
  Ne pas éditer à la main : modifier le .sql puis relancer le script.

  Crée les index sur les tables sources GRACE THD.
  - schéma source résolu dynamiquement via le graph dbt (source 'gracethd') ;
  - non-bloquant : table + colonnes vérifiées dans information_schema avant CREATE ;
  - idempotent : index déjà présents ignorés + CREATE INDEX IF NOT EXISTS.

  Appel typique (pre-hook configuré dans dbt_project.yml) :
    +pre-hook: ["{{ create_source_indexes() }}"]
#}
{% macro create_source_indexes() %}
  {%- if not execute -%}{{ return('') }}{%- endif -%}

  {%- set src_schema = (graph.sources.values()
        | selectattr('source_name', 'equalto', 'gracethd')
        | list | first).schema -%}

  {%- set indexes = [
    {"name": "t_organisme_pk_idx", "table": "t_organisme", "cols": ["or_code"], "unique": false, "method": none},
    {"name": "t_document_pk_idx", "table": "t_document", "cols": ["do_code"], "unique": false, "method": none},
    {"name": "t_docobj_pk_idx", "table": "t_docobj", "cols": ["od_id"], "unique": false, "method": none},
    {"name": "t_empreinte_pk_idx", "table": "t_empreinte", "cols": ["em_code"], "unique": false, "method": none},
    {"name": "t_reference_pk_idx", "table": "t_reference", "cols": ["rf_code"], "unique": false, "method": none},
    {"name": "t_adresse_pk_idx", "table": "t_adresse", "cols": ["ad_code"], "unique": false, "method": none},
    {"name": "t_noeud_pk_idx", "table": "t_noeud", "cols": ["nd_code"], "unique": false, "method": none},
    {"name": "t_ptech_pk_idx", "table": "t_ptech", "cols": ["pt_code"], "unique": false, "method": none},
    {"name": "t_ebp_pk_idx", "table": "t_ebp", "cols": ["bp_code"], "unique": false, "method": none},
    {"name": "t_cheminement_pk_idx", "table": "t_cheminement", "cols": ["cm_code"], "unique": false, "method": none},
    {"name": "t_site_pk_idx", "table": "t_site", "cols": ["st_code"], "unique": false, "method": none},
    {"name": "t_local_pk_idx", "table": "t_local", "cols": ["lc_code"], "unique": false, "method": none},
    {"name": "t_baie_pk_idx", "table": "t_baie", "cols": ["ba_code"], "unique": false, "method": none},
    {"name": "t_cable_pk_idx", "table": "t_cable", "cols": ["cb_code"], "unique": false, "method": none},
    {"name": "t_cableline_pk_idx", "table": "t_cableline", "cols": ["cl_code"], "unique": false, "method": none},
    {"name": "t_cab_chem_pk_idx", "table": "t_cab_chem", "cols": ["cc_cb_code", "cc_cm_code"], "unique": false, "method": none},
    {"name": "t_love_pk_idx", "table": "t_love", "cols": ["lv_id"], "unique": false, "method": none},
    {"name": "t_tiroir_pk_idx", "table": "t_tiroir", "cols": ["ti_code"], "unique": false, "method": none},
    {"name": "t_cassette_pk_idx", "table": "t_cassette", "cols": ["cs_code"], "unique": false, "method": none},
    {"name": "t_fibre_pk_idx", "table": "t_fibre", "cols": ["fo_code"], "unique": false, "method": none},
    {"name": "t_position_pk_idx", "table": "t_position", "cols": ["ps_code"], "unique": false, "method": none},
    {"name": "t_znro_pk_idx", "table": "t_znro", "cols": ["zn_code"], "unique": false, "method": none},
    {"name": "t_zsro_pk_idx", "table": "t_zsro", "cols": ["zs_code"], "unique": false, "method": none},
    {"name": "t_zdep_pk_idx", "table": "t_zdep", "cols": ["zd_code"], "unique": false, "method": none},
    {"name": "t_zpbo_pk_idx", "table": "t_zpbo", "cols": ["zp_code"], "unique": false, "method": none},
    {"name": "t_zcoax_pk_idx", "table": "t_zcoax", "cols": ["zc_code"], "unique": false, "method": none},
    {"name": "t_ropt_pk_idx", "table": "t_ropt", "cols": ["rt_code"], "unique": false, "method": none},
    {"name": "t_pointaccueil_pk_idx", "table": "t_pointaccueil", "cols": ["pa_code"], "unique": false, "method": none},
    {"name": "t_tranchee_pk_idx", "table": "t_tranchee", "cols": ["tr_code"], "unique": false, "method": none},
    {"name": "t_point_leve_pk_idx", "table": "t_point_leve", "cols": ["pl_code"], "unique": false, "method": none},
    {"name": "ad_ban_id_idx", "table": "t_adresse", "cols": ["ad_ban_id"], "unique": false, "method": none},
    {"name": "ad_x_ban_idx", "table": "t_adresse", "cols": ["ad_x_ban"], "unique": false, "method": none},
    {"name": "ad_y_ban_idx", "table": "t_adresse", "cols": ["ad_y_ban"], "unique": false, "method": none},
    {"name": "ad_idpar_idx", "table": "t_adresse", "cols": ["ad_idpar"], "unique": false, "method": none},
    {"name": "ad_x_parc_idx", "table": "t_adresse", "cols": ["ad_x_parc"], "unique": false, "method": none},
    {"name": "ad_y_parc_idx", "table": "t_adresse", "cols": ["ad_y_parc"], "unique": false, "method": none},
    {"name": "ad_nbplres_idx", "table": "t_adresse", "cols": ["ad_nblres"], "unique": false, "method": none},
    {"name": "ad_nbplpro_idx", "table": "t_adresse", "cols": ["ad_nblpro"], "unique": false, "method": none},
    {"name": "ad_nbplent_idx", "table": "t_adresse", "cols": ["ad_nblent"], "unique": false, "method": none},
    {"name": "ad_nblpub_idx", "table": "t_adresse", "cols": ["ad_nblpub"], "unique": false, "method": none},
    {"name": "ad_hexacle_idx", "table": "t_adresse", "cols": ["ad_hexacle"], "unique": false, "method": none},
    {"name": "ad_hexaclv_idx", "table": "t_adresse", "cols": ["ad_hexaclv"], "unique": false, "method": none},
    {"name": "ad_racc_idx", "table": "t_adresse", "cols": ["ad_racc"], "unique": false, "method": none},
    {"name": "ad_ietat_idx", "table": "t_adresse", "cols": ["ad_ietat"], "unique": false, "method": none},
    {"name": "ad_itypeim_idx", "table": "t_adresse", "cols": ["ad_itypeim"], "unique": false, "method": none},
    {"name": "ad_typzone_idx", "table": "t_adresse", "cols": ["ad_typzone"], "unique": false, "method": none},
    {"name": "or_nom_idx", "table": "t_organisme", "cols": ["or_nom"], "unique": false, "method": none},
    {"name": "or_l331_idx", "table": "t_organisme", "cols": ["or_l331"], "unique": false, "method": none},
    {"name": "or_siret_idx", "table": "t_organisme", "cols": ["or_siret"], "unique": false, "method": none},
    {"name": "or_nometab_idx", "table": "t_organisme", "cols": ["or_nometab"], "unique": false, "method": none},
    {"name": "or_ad_code_idx", "table": "t_organisme", "cols": ["or_ad_code"], "unique": false, "method": none},
    {"name": "rf_type_idx", "table": "t_reference", "cols": ["rf_type"], "unique": false, "method": none},
    {"name": "rf_fabric_idx", "table": "t_reference", "cols": ["rf_fabric"], "unique": false, "method": none},
    {"name": "rf_etat_idx", "table": "t_reference", "cols": ["rf_etat"], "unique": false, "method": none},
    {"name": "zn_nd_code_idx", "table": "t_znro", "cols": ["zn_nd_code"], "unique": false, "method": none},
    {"name": "zn_r1_code_idx", "table": "t_znro", "cols": ["zn_r1_code"], "unique": false, "method": none},
    {"name": "zn_r2_code_idx", "table": "t_znro", "cols": ["zn_r2_code"], "unique": false, "method": none},
    {"name": "zn_r3_code_idx", "table": "t_znro", "cols": ["zn_r3_code"], "unique": false, "method": none},
    {"name": "zn_r4_code_idx", "table": "t_znro", "cols": ["zn_r4_code"], "unique": false, "method": none},
    {"name": "zs_nd_code_idx", "table": "t_zsro", "cols": ["zs_nd_code"], "unique": false, "method": none},
    {"name": "zs_zn_code_idx", "table": "t_zsro", "cols": ["zs_zn_code"], "unique": false, "method": none},
    {"name": "zs_r1_code_idx", "table": "t_zsro", "cols": ["zs_r1_code"], "unique": false, "method": none},
    {"name": "zs_r2_code_idx", "table": "t_zsro", "cols": ["zs_r2_code"], "unique": false, "method": none},
    {"name": "zs_r3_code_idx", "table": "t_zsro", "cols": ["zs_r3_code"], "unique": false, "method": none},
    {"name": "zs_r4_code_idx", "table": "t_zsro", "cols": ["zs_r4_code"], "unique": false, "method": none},
    {"name": "zp_nd_code_idx", "table": "t_zpbo", "cols": ["zp_nd_code"], "unique": false, "method": none},
    {"name": "zp_zs_code_idx", "table": "t_zpbo", "cols": ["zp_zs_code"], "unique": false, "method": none},
    {"name": "zp_r1_code_idx", "table": "t_zpbo", "cols": ["zp_r1_code"], "unique": false, "method": none},
    {"name": "zp_r2_code_idx", "table": "t_zpbo", "cols": ["zp_r2_code"], "unique": false, "method": none},
    {"name": "zp_r3_code_idx", "table": "t_zpbo", "cols": ["zp_r3_code"], "unique": false, "method": none},
    {"name": "zp_r4_code_idx", "table": "t_zpbo", "cols": ["zp_r4_code"], "unique": false, "method": none},
    {"name": "zd_nd_code_idx", "table": "t_zdep", "cols": ["zd_nd_code"], "unique": false, "method": none},
    {"name": "zd_zs_code_idx", "table": "t_zdep", "cols": ["zd_zs_code"], "unique": false, "method": none},
    {"name": "zd_r1_code_idx", "table": "t_zdep", "cols": ["zd_r1_code"], "unique": false, "method": none},
    {"name": "zd_r2_code_idx", "table": "t_zdep", "cols": ["zd_r2_code"], "unique": false, "method": none},
    {"name": "zd_r3_code_idx", "table": "t_zdep", "cols": ["zd_r3_code"], "unique": false, "method": none},
    {"name": "zd_r4_code_idx", "table": "t_zdep", "cols": ["zd_r4_code"], "unique": false, "method": none},
    {"name": "zd_prop_idx", "table": "t_zdep", "cols": ["zd_prop"], "unique": false, "method": none},
    {"name": "zd_gest_idx", "table": "t_zdep", "cols": ["zd_gest"], "unique": false, "method": none},
    {"name": "zd_statut_idx", "table": "t_zdep", "cols": ["zd_statut"], "unique": false, "method": none},
    {"name": "zc_nd_code_idx", "table": "t_zcoax", "cols": ["zc_nd_code"], "unique": false, "method": none},
    {"name": "zc_r1_code_idx", "table": "t_zcoax", "cols": ["zc_r1_code"], "unique": false, "method": none},
    {"name": "zc_r2_code_idx", "table": "t_zcoax", "cols": ["zc_r2_code"], "unique": false, "method": none},
    {"name": "zc_r3_code_idx", "table": "t_zcoax", "cols": ["zc_r3_code"], "unique": false, "method": none},
    {"name": "zc_r4_code_idx", "table": "t_zcoax", "cols": ["zc_r4_code"], "unique": false, "method": none},
    {"name": "zc_prop_idx", "table": "t_zcoax", "cols": ["zc_prop"], "unique": false, "method": none},
    {"name": "zc_gest_idx", "table": "t_zcoax", "cols": ["zc_gest"], "unique": false, "method": none},
    {"name": "zc_statut_idx", "table": "t_zcoax", "cols": ["zc_statut"], "unique": false, "method": none},
    {"name": "lc_st_code_idx", "table": "t_local", "cols": ["lc_st_code"], "unique": false, "method": none},
    {"name": "lc_bp_codf_idx", "table": "t_local", "cols": ["lc_bp_codf"], "unique": false, "method": none},
    {"name": "lc_bp_codp_idx", "table": "t_local", "cols": ["lc_bp_codp"], "unique": false, "method": none},
    {"name": "lc_typelog_idx", "table": "t_local", "cols": ["lc_typelog"], "unique": false, "method": none},
    {"name": "lc_prop_idx", "table": "t_local", "cols": ["lc_prop"], "unique": false, "method": none},
    {"name": "lc_gest_idx", "table": "t_local", "cols": ["lc_gest"], "unique": false, "method": none},
    {"name": "lc_proptyp_idx", "table": "t_local", "cols": ["lc_proptyp"], "unique": false, "method": none},
    {"name": "lc_statut_idx", "table": "t_local", "cols": ["lc_statut"], "unique": false, "method": none},
    {"name": "lc_avct_idx", "table": "t_local", "cols": ["lc_avct"], "unique": false, "method": none},
    {"name": "lc_etiquet_idx", "table": "t_local", "cols": ["lc_etiquet"], "unique": false, "method": none},
    {"name": "ba_etiquet_idx", "table": "t_baie", "cols": ["ba_etiquet"], "unique": false, "method": none},
    {"name": "ba_prop_idx", "table": "t_baie", "cols": ["ba_prop"], "unique": false, "method": none},
    {"name": "ba_gest_idx", "table": "t_baie", "cols": ["ba_gest"], "unique": false, "method": none},
    {"name": "ba_proptyp_idx", "table": "t_baie", "cols": ["ba_proptyp"], "unique": false, "method": none},
    {"name": "ba_statut_idx", "table": "t_baie", "cols": ["ba_statut"], "unique": false, "method": none},
    {"name": "ba_etat_idx", "table": "t_baie", "cols": ["ba_etat"], "unique": false, "method": none},
    {"name": "ba_rf_code_idx", "table": "t_baie", "cols": ["ba_rf_code"], "unique": false, "method": none},
    {"name": "ba_type_idx", "table": "t_baie", "cols": ["ba_type"], "unique": false, "method": none},
    {"name": "ti_ba_code_idx", "table": "t_tiroir", "cols": ["ti_ba_code"], "unique": false, "method": none},
    {"name": "ti_prop_idx", "table": "t_tiroir", "cols": ["ti_prop"], "unique": false, "method": none},
    {"name": "ti_etat_idx", "table": "t_tiroir", "cols": ["ti_etat"], "unique": false, "method": none},
    {"name": "ti_type_idx", "table": "t_tiroir", "cols": ["ti_type"], "unique": false, "method": none},
    {"name": "ti_rf_code_idx", "table": "t_tiroir", "cols": ["ti_rf_code"], "unique": false, "method": none},
    {"name": "pt_nd_code_idx", "table": "t_ptech", "cols": ["pt_nd_code"], "unique": false, "method": none},
    {"name": "pt_ad_code_idx", "table": "t_ptech", "cols": ["pt_ad_code"], "unique": false, "method": none},
    {"name": "pt_gest_do_idx", "table": "t_ptech", "cols": ["pt_gest_do"], "unique": false, "method": none},
    {"name": "pt_prop_do_idx", "table": "t_ptech", "cols": ["pt_prop_do"], "unique": false, "method": none},
    {"name": "pt_prop_idx", "table": "t_ptech", "cols": ["pt_prop"], "unique": false, "method": none},
    {"name": "pt_gest_idx", "table": "t_ptech", "cols": ["pt_gest"], "unique": false, "method": none},
    {"name": "pt_proptyp_idx", "table": "t_ptech", "cols": ["pt_proptyp"], "unique": false, "method": none},
    {"name": "pt_statut_idx", "table": "t_ptech", "cols": ["pt_statut"], "unique": false, "method": none},
    {"name": "pt_etat_idx", "table": "t_ptech", "cols": ["pt_etat"], "unique": false, "method": none},
    {"name": "pt_avct_idx", "table": "t_ptech", "cols": ["pt_avct"], "unique": false, "method": none},
    {"name": "pt_typephy_idx", "table": "t_ptech", "cols": ["pt_typephy"], "unique": false, "method": none},
    {"name": "pt_typelog_idx", "table": "t_ptech", "cols": ["pt_typelog"], "unique": false, "method": none},
    {"name": "pt_rf_code_idx", "table": "t_ptech", "cols": ["pt_rf_code"], "unique": false, "method": none},
    {"name": "pt_nature_idx", "table": "t_ptech", "cols": ["pt_nature"], "unique": false, "method": none},
    {"name": "bp_pt_code_idx", "table": "t_ebp", "cols": ["bp_pt_code"], "unique": false, "method": none},
    {"name": "bp_prop_idx", "table": "t_ebp", "cols": ["bp_prop"], "unique": false, "method": none},
    {"name": "bp_gest_idx", "table": "t_ebp", "cols": ["bp_gest"], "unique": false, "method": none},
    {"name": "bp_proptyp_idx", "table": "t_ebp", "cols": ["bp_proptyp"], "unique": false, "method": none},
    {"name": "bp_statut_idx", "table": "t_ebp", "cols": ["bp_statut"], "unique": false, "method": none},
    {"name": "bp_etat_idx", "table": "t_ebp", "cols": ["bp_etat"], "unique": false, "method": none},
    {"name": "bp_avct_idx", "table": "t_ebp", "cols": ["bp_avct"], "unique": false, "method": none},
    {"name": "bp_rf_code_idx", "table": "t_ebp", "cols": ["bp_rf_code"], "unique": false, "method": none},
    {"name": "cs_bp_code_idx", "table": "t_cassette", "cols": ["cs_bp_code"], "unique": false, "method": none},
    {"name": "cs_type_idx", "table": "t_cassette", "cols": ["cs_type"], "unique": false, "method": none},
    {"name": "cs_rf_code_idx", "table": "t_cassette", "cols": ["cs_rf_code"], "unique": false, "method": none},
    {"name": "cm_ndcode1_idx", "table": "t_cheminement", "cols": ["cm_ndcode1"], "unique": false, "method": none},
    {"name": "cm_ndcode2_idx", "table": "t_cheminement", "cols": ["cm_ndcode2"], "unique": false, "method": none},
    {"name": "cm_gest_idx", "table": "t_cheminement", "cols": ["cm_gest"], "unique": false, "method": none},
    {"name": "cm_prop_idx", "table": "t_cheminement", "cols": ["cm_prop"], "unique": false, "method": none},
    {"name": "cm_statut_idx", "table": "t_cheminement", "cols": ["cm_statut"], "unique": false, "method": none},
    {"name": "cm_avct_idx", "table": "t_cheminement", "cols": ["cm_avct"], "unique": false, "method": none},
    {"name": "cm_typelog_idx", "table": "t_cheminement", "cols": ["cm_typelog"], "unique": false, "method": none},
    {"name": "cm_typ_imp_idx", "table": "t_cheminement", "cols": ["cm_typ_imp"], "unique": false, "method": none},
    {"name": "cb_nd1_idx", "table": "t_cable", "cols": ["cb_nd1"], "unique": false, "method": none},
    {"name": "cb_nd2_idx", "table": "t_cable", "cols": ["cb_nd2"], "unique": false, "method": none},
    {"name": "cb_prop_idx", "table": "t_cable", "cols": ["cb_prop"], "unique": false, "method": none},
    {"name": "cb_gest_idx", "table": "t_cable", "cols": ["cb_gest"], "unique": false, "method": none},
    {"name": "cb_proptyp_idx", "table": "t_cable", "cols": ["cb_proptyp"], "unique": false, "method": none},
    {"name": "cb_statut_idx", "table": "t_cable", "cols": ["cb_statut"], "unique": false, "method": none},
    {"name": "cb_etat_idx", "table": "t_cable", "cols": ["cb_etat"], "unique": false, "method": none},
    {"name": "cb_avct_idx", "table": "t_cable", "cols": ["cb_avct"], "unique": false, "method": none},
    {"name": "cb_typephy_idx", "table": "t_cable", "cols": ["cb_typephy"], "unique": false, "method": none},
    {"name": "cb_typelog_idx", "table": "t_cable", "cols": ["cb_typelog"], "unique": false, "method": none},
    {"name": "lv_unique_idx", "table": "t_love", "cols": ["lv_cb_code", "lv_nd_code"], "unique": true, "method": none},
    {"name": "fo_cb_code_idx", "table": "t_fibre", "cols": ["fo_cb_code"], "unique": false, "method": none},
    {"name": "fo_etat_idx", "table": "t_fibre", "cols": ["fo_etat"], "unique": false, "method": none},
    {"name": "fo_proptyp_idx", "table": "t_fibre", "cols": ["fo_proptyp"], "unique": false, "method": none},
    {"name": "ps_numero_idx", "table": "t_position", "cols": ["ps_numero"], "unique": false, "method": none},
    {"name": "ps_1_idx", "table": "t_position", "cols": ["ps_1"], "unique": false, "method": none},
    {"name": "ps_2_idx", "table": "t_position", "cols": ["ps_2"], "unique": false, "method": none},
    {"name": "ps_cs_code_idx", "table": "t_position", "cols": ["ps_cs_code"], "unique": false, "method": none},
    {"name": "ps_ti_code_idx", "table": "t_position", "cols": ["ps_ti_code"], "unique": false, "method": none},
    {"name": "ps_type_idx", "table": "t_position", "cols": ["ps_type"], "unique": false, "method": none},
    {"name": "ps_fonct_idx", "table": "t_position", "cols": ["ps_fonct"], "unique": false, "method": none},
    {"name": "ps_etat_idx", "table": "t_position", "cols": ["ps_etat"], "unique": false, "method": none},
    {"name": "rt_code_idx", "table": "t_ropt", "cols": ["rt_code"], "unique": false, "method": none},
    {"name": "rt_fo_code_idx", "table": "t_ropt", "cols": ["rt_fo_code"], "unique": false, "method": none},
    {"name": "do_ref_idx", "table": "t_document", "cols": ["do_ref"], "unique": false, "method": none},
    {"name": "do_r1_code_idx", "table": "t_document", "cols": ["do_r1_code"], "unique": false, "method": none},
    {"name": "do_r2_code_idx", "table": "t_document", "cols": ["do_r2_code"], "unique": false, "method": none},
    {"name": "do_r3_code_idx", "table": "t_document", "cols": ["do_r3_code"], "unique": false, "method": none},
    {"name": "do_r4_code_idx", "table": "t_document", "cols": ["do_r4_code"], "unique": false, "method": none},
    {"name": "do_type_idx", "table": "t_document", "cols": ["do_type"], "unique": false, "method": none},
    {"name": "do_date_idx", "table": "t_document", "cols": ["do_date"], "unique": false, "method": none},
    {"name": "do_url1_idx", "table": "t_document", "cols": ["do_url1"], "unique": false, "method": none},
    {"name": "do_url2_idx", "table": "t_document", "cols": ["do_url2"], "unique": false, "method": none},
    {"name": "od_do_code_idx", "table": "t_docobj", "cols": ["od_do_code"], "unique": false, "method": none},
    {"name": "em_do_code_idx", "table": "t_empreinte", "cols": ["em_do_code"], "unique": false, "method": none},
    {"name": "t_adresse_geom_idx", "table": "t_adresse", "cols": ["geom"], "unique": false, "method": "gist"},
    {"name": "t_cableline_geom_idx", "table": "t_cableline", "cols": ["geom"], "unique": false, "method": "gist"},
    {"name": "t_cheminement_geom_idx", "table": "t_cheminement", "cols": ["geom"], "unique": false, "method": "gist"},
    {"name": "t_noeud_geom_idx", "table": "t_noeud", "cols": ["geom"], "unique": false, "method": "gist"},
    {"name": "t_point_leve_geom_idx", "table": "t_point_leve", "cols": ["geom"], "unique": false, "method": "gist"},
    {"name": "t_pointaccueil_geom_idx", "table": "t_pointaccueil", "cols": ["geom"], "unique": false, "method": "gist"},
    {"name": "t_tranchee_geom_idx", "table": "t_tranchee", "cols": ["geom"], "unique": false, "method": "gist"},
    {"name": "t_zdep_geom_idx", "table": "t_zdep", "cols": ["geom"], "unique": false, "method": "gist"},
    {"name": "t_znro_geom_idx", "table": "t_znro", "cols": ["geom"], "unique": false, "method": "gist"},
    {"name": "t_zsro_geom_idx", "table": "t_zsro", "cols": ["geom"], "unique": false, "method": "gist"},
  ] -%}

  {#- Colonnes réellement présentes : "table.colonne" -#}
  {%- set col_rows = run_query(
      "select table_name || '.' || column_name from information_schema.columns"
      ~ " where table_schema = '" ~ src_schema ~ "'"
  ) -%}
  {%- set existing_cols = col_rows.columns[0].values() | list if col_rows else [] -%}

  {#- Index déjà présents -#}
  {%- set idx_rows = run_query(
      "select indexname from pg_indexes where schemaname = '" ~ src_schema ~ "'"
  ) -%}
  {%- set existing_idx = idx_rows.columns[0].values() | list if idx_rows else [] -%}

  {%- for ix in indexes -%}
    {%- if ix.name not in existing_idx -%}
      {%- set ns = namespace(ok=true) -%}
      {%- for c in ix.cols -%}
        {%- if (ix.table ~ '.' ~ c) not in existing_cols -%}{%- set ns.ok = false -%}{%- endif -%}
      {%- endfor -%}
      {%- if ns.ok -%}
        {%- set ddl = "create " ~ ("unique " if ix.unique else "")
              ~ "index if not exists " ~ ix.name
              ~ " on " ~ src_schema ~ "." ~ ix.table
              ~ (" using " ~ ix.method if ix.method else "")
              ~ " (" ~ (ix.cols | join(", ")) ~ ")" -%}
        {%- do run_query(ddl) -%}
        {%- do log("Index créé : " ~ ix.name, info=true) -%}
      {%- endif -%}
    {%- endif -%}
  {%- endfor -%}

  {#- Corps du hook : no-op valide (les CREATE ont été exécutés via run_query) -#}
  {{ return('select 1') }}
{% endmacro %}
