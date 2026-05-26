{{ config(tags=['grace_rapport', 'grace_synthese']) }}

with entites_totales as (
  select 't_adresse' as classe, count(*) as total from {{ source('gracethd', 't_adresse') }} union all
  select 't_baie', count(*) from {{ source('gracethd', 't_baie') }} union all
  select 't_cab_chem', count(*) from {{ source('gracethd', 't_cab_chem') }} union all
  select 't_cable', count(*) from {{ source('gracethd', 't_cable') }} union all
  select 't_cableline', count(*) from {{ source('gracethd', 't_cableline') }} union all
  select 't_cassette', count(*) from {{ source('gracethd', 't_cassette') }} union all
  select 't_cheminement', count(*) from {{ source('gracethd', 't_cheminement') }} union all
  select 't_ebp', count(*) from {{ source('gracethd', 't_ebp') }} union all
  select 't_fibre', count(*) from {{ source('gracethd', 't_fibre') }} union all
  select 't_local', count(*) from {{ source('gracethd', 't_local') }} union all
  select 't_love', count(*) from {{ source('gracethd', 't_love') }} union all
  select 't_noeud', count(*) from {{ source('gracethd', 't_noeud') }} union all
  select 't_organisme', count(*) from {{ source('gracethd', 't_organisme') }} union all
  select 't_point_leve', count(*) from {{ source('gracethd', 't_point_leve') }} union all
  select 't_pointaccueil', count(*) from {{ source('gracethd', 't_pointaccueil') }} union all
  select 't_position', count(*) from {{ source('gracethd', 't_position') }} union all
  select 't_ptech', count(*) from {{ source('gracethd', 't_ptech') }} union all
  select 't_reference', count(*) from {{ source('gracethd', 't_reference') }} union all
  select 't_site', count(*) from {{ source('gracethd', 't_site') }} union all
  select 't_tiroir', count(*) from {{ source('gracethd', 't_tiroir') }} union all
  select 't_tranchee', count(*) from {{ source('gracethd', 't_tranchee') }} union all
  select 't_zdep', count(*) from {{ source('gracethd', 't_zdep') }} union all
  select 't_znro', count(*) from {{ source('gracethd', 't_znro') }} union all
  select 't_zsro', count(*) from {{ source('gracethd', 't_zsro') }}
)

select
  r.id_test,
  r.type_controle,
  r.description,
  r.classe,
  r.attribut,
  count(*) as nombre_erreurs,
  e.total as entites_total,
  round(count(*) * 100.0 / nullif(e.total, 0), 2) as pct_erreur
from {{ ref('rapport_controles') }} r
left join entites_totales e on r.classe = e.classe
group by
  r.id_test, r.type_controle, r.description, r.classe, r.attribut, e.total
order by
  pct_erreur desc nulls last, id_test
