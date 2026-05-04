{{ config(materialized='table', tags=['rapport', 'synthese']) }}

select
  id_test,
  type_controle,
  description,
  classe,
  attribut,
  count(*) as nombre_erreurs
from {{ ref('rapport_controles') }}
group by
  id_test, type_controle, description, classe, attribut
order by
  nombre_erreurs desc, id_test
