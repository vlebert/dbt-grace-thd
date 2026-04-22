{% macro ctrl_specifique(
    id_test,
    type_controle,
    classe,
    cle_primaire,
    attribut,
    description,
    requ_princ,
    condition,
    detail_erreur="NULL::text"
) %}

select
    '{{ id_test }}'::text             as id_test,
    '{{ type_controle }}'::text       as type_controle,
    '{{ description }}'::text         as description,
    '{{ classe }}'::text              as classe,
    '{{ attribut }}'::text            as attribut,
    src."{{ cle_primaire }}"::text    as id_entite,
    {{ detail_erreur }}               as detail_erreur
from ({{ requ_princ }}) as src
where {{ condition }}

{% endmacro %}
