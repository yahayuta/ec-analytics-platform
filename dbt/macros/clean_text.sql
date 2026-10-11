{#- Normalise free-text keys coming from source systems: trim + lowercase. -#}
{% macro clean_text(column_name) -%}
    lower(trim({{ column_name }}))
{%- endmacro %}
