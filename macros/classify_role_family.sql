{% macro classify_role_family(job_title_col) %}
    case
        -- English patterns
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
        -- Slovak patterns (profesia.sk titles)
        when lower({{ job_title_col }}) like '%dátový inžinier%'       then 'Data Engineering'
        when lower({{ job_title_col }}) like '%datový inžinier%'       then 'Data Engineering'
        when lower({{ job_title_col }}) like '%inžinier dát%'          then 'Data Engineering'
        when lower({{ job_title_col }}) like '%dátový analytik%'       then 'Data Analytics'
        when lower({{ job_title_col }}) like '%datový analytik%'       then 'Data Analytics'
        when lower({{ job_title_col }}) like '%analytik dát%'          then 'Data Analytics'
        when lower({{ job_title_col }}) like '%bi analytik%'           then 'Data Analytics'
        when lower({{ job_title_col }}) like '%business analytik%'     then 'Data Analytics'
        when lower({{ job_title_col }}) like '%biznis analytik%'       then 'Data Analytics'
        when lower({{ job_title_col }}) like '%dátový vedec%'          then 'Data Science'
        when lower({{ job_title_col }}) like '%datový vedec%'          then 'Data Science'
        when lower({{ job_title_col }}) like '%strojové učenie%'       then 'ML / AI Engineering'
        when lower({{ job_title_col }}) like '%správca databáz%'       then 'Database Administration'
        -- broad Slovak analyst catch (after more specific patterns above)
        when lower({{ job_title_col }}) like '%analytik%'              then 'Data Analytics'
        else                                                                 'Other'
    end
{% endmacro %}
