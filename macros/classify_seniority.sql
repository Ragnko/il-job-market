{% macro classify_seniority(years_col) %}
    case
        when {{ years_col }} is null  then 'Unknown'
        when {{ years_col }} < 3      then 'Junior'
        when {{ years_col }} < 6      then 'Mid'
        when {{ years_col }} < 10     then 'Senior'
        else                               'Staff / Lead'
    end
{% endmacro %}
