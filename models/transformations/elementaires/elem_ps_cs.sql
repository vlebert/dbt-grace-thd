SELECT
  ps.id,
  ps.ps_code,
  ps.ps_1,
  ps.ps_2,
  ps.ps_numero,
  ps.ps_cs_code,
  ps.ps_type,
  ps.ps_fonct,
  ps.ps_preaff,
  ps.ps_ti_code,
  cs.geom AS geom
FROM {{ ref('t_position') }} AS ps
INNER JOIN {{ ref('elem_cs') }} AS cs
  ON ps.ps_cs_code = cs.cs_code
