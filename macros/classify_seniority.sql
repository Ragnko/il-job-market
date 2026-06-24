{% macro classify_seniority(exp_level_col) %}
    case
        when {{ exp_level_col }} = 'EN' then 'Junior'
        when {{ exp_level_col }} = 'MI' then 'Mid'
        when {{ exp_level_col }} = 'SE' then 'Senior'
        when {{ exp_level_col }} = 'EX' then 'Staff / Lead'
        else                                 'Unknown'
    end
{% endmacro %}
