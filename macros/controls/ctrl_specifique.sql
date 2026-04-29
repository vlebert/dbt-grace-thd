{% macro ctrl_specifique(
    id_test,
    type_controle,
    classe,
    cle_primaire,
    attribut,
    description,
    requ_princ,
    condition,
    detail_erreur="NULL::text",
    is_active=true
) %}

{% if is_active %}
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
{% else %}
select
    $str${{ id_test }}$str$::text as id_test,
    $str${{ type_controle }}$str$::text as type_controle,
    NULL::text as description,
    NULL::text as classe,
    NULL::text as attribut,
    NULL::text as id_entite,
    NULL::text as detail_erreur
where false
{% endif %}

{% endmacro %}
