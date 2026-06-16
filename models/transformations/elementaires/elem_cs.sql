{{
    config(
        materialized = 'table',
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['cs_code'], 'type': 'btree'},
            {'columns': ['cs_bp_code'], 'type': 'btree'},
            {'columns': ['cs_rf_code'], 'type': 'btree'},
            {'columns': ['cs_type'], 'type': 'btree'},
            {'columns': ['geom'], 'type': 'gist'}
        ]
    )
}}

-- Matérialisé en table : UNION ALL de deux sources dont les `id` (issus de
-- t_cassette) peuvent se recouvrir. L'`id` est régénéré via row_number() pour
-- garantir une clé primaire unique non bloquante. Les index reproduisent ceux
-- de la table base t_cassette (+ gist sur geom).
WITH combined AS (
  SELECT
    cs_code,
    cs_bp_code,
    cs_num,
    cs_type,
    cs_face,
    cs_rf_code,
    geom
  FROM {{ ref('elem_cs_bp') }}
  UNION ALL
  SELECT
    cs_code,
    cs_bp_code,
    cs_num,
    cs_type,
    cs_face,
    cs_rf_code,
    geom
  FROM {{ ref('elem_cs_ti') }}
)
SELECT
  row_number() OVER (ORDER BY cs_code)::int4 AS id,
  cs_code,
  cs_bp_code,
  cs_num,
  cs_type,
  cs_face,
  cs_rf_code,
  geom
FROM combined
