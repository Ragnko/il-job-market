{% macro classify_role_family(dev_type_col) %}
    case
        when {{ dev_type_col }} like '%Data engineer%'              then 'Data Engineering'
        when {{ dev_type_col }} like '%Data or business analyst%'   then 'Data Analytics'
        when {{ dev_type_col }} like '%Data scientist%'             then 'Data Science'
        when {{ dev_type_col }} like '%machine learning%'           then 'ML / AI Engineering'
        when {{ dev_type_col }} like '%Database administrator%'     then 'Database Administration'
        else                                                              'Other'
    end
{% endmacro %}
