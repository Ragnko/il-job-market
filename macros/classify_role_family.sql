{% macro classify_role_family(job_title_col) %}
    case
        when lower({{ job_title_col }}) like '%data engineer%'         then 'Data Engineering'
        when lower({{ job_title_col }}) like '%analytics engineer%'    then 'Data Engineering'
        when lower({{ job_title_col }}) like '%data analyst%'          then 'Data Analytics'
        when lower({{ job_title_col }}) like '%business analyst%'      then 'Data Analytics'
        when lower({{ job_title_col }}) like '%bi %'                   then 'Data Analytics'
        when lower({{ job_title_col }}) like '%data scientist%'        then 'Data Science'
        when lower({{ job_title_col }}) like '%research scientist%'    then 'Data Science'
        when lower({{ job_title_col }}) like '%machine learning%'      then 'ML / AI Engineering'
        when lower({{ job_title_col }}) like '%ml engineer%'           then 'ML / AI Engineering'
        when lower({{ job_title_col }}) like '%ai engineer%'           then 'ML / AI Engineering'
        when lower({{ job_title_col }}) like '%nlp%'                   then 'ML / AI Engineering'
        when lower({{ job_title_col }}) like '%database%'              then 'Database Administration'
        when lower({{ job_title_col }}) like '%dba%'                   then 'Database Administration'
        else                                                                 'Other'
    end
{% endmacro %}
