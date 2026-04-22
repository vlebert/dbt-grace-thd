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
    $str${{ id_test }}$str$::text             as id_test,
    $str${{ type_controle }}$str$::text       as type_controle,
    $str${{ description }}$str$::text         as description,
    $str${{ classe }}$str$::text              as classe,
    $str${{ attribut }}$str$::text            as attribut,
    src."{{ cle_primaire }}"::text    as id_entite,
    {{ detail_erreur }}               as detail_erreur
from ({{ requ_princ }}) as src
where {{ condition }}

{% endmacro %}
