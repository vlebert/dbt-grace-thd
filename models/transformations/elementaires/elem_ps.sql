{{
    config(
        materialized = 'table',
        post_hook = ["ALTER TABLE {{ this }} ADD PRIMARY KEY (id);"],
        indexes = [
            {'columns': ['ps_code'], 'type': 'btree'},
            {'columns': ['ps_numero'], 'type': 'btree'},
            {'columns': ['ps_1'], 'type': 'btree'},
            {'columns': ['ps_2'], 'type': 'btree'},
            {'columns': ['ps_cs_code'], 'type': 'btree'},
            {'columns': ['ps_ti_code'], 'type': 'btree'},
            {'columns': ['ps_type'], 'type': 'btree'},
            {'columns': ['ps_fonct'], 'type': 'btree'},
            {'columns': ['geom'], 'type': 'gist'}
        ]
    )
}}

-- Matérialisé en table : UNION ALL de deux sources dont les `id` (issus de
-- t_position) peuvent se recouvrir. L'`id` est régénéré via row_number() pour
-- garantir une clé primaire unique non bloquante. Les index reproduisent ceux
-- de la table base t_position (+ gist sur geom).
WITH combined AS (
  SELECT
    ps_code,
    ps_1,
    ps_2,
    ps_numero,
    ps_cs_code,
    ps_type,
    ps_fonct,
    ps_preaff,
    ps_ti_code,
    geom
  FROM {{ ref('elem_ps_cs') }}
  UNION ALL
  SELECT
    ps_code,
    ps_1,
    ps_2,
    ps_numero,
    ps_cs_code,
    ps_type,
    ps_fonct,
    ps_preaff,
    ps_ti_code,
    geom
  FROM {{ ref('elem_ps_ti') }}
)
SELECT
  row_number() OVER (ORDER BY ps_code) AS id,
  ps_code,
  ps_1,
  ps_2,
  ps_numero,
  ps_cs_code,
  ps_type,
  ps_fonct,
  ps_preaff,
  ps_ti_code,
  geom
FROM combined
