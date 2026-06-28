{% macro classify_role_family(job_title_col) %}
    case
        -- English patterns — Data Engineering
        when lower({{ job_title_col }}) like '%data engineer%'         then 'Data Engineering'
        when lower({{ job_title_col }}) like '%analytics engineer%'    then 'Data Engineering'
        when lower({{ job_title_col }}) like '%data platform%'         then 'Data Engineering'
        when lower({{ job_title_col }}) like '%data pipeline%'         then 'Data Engineering'
        when lower({{ job_title_col }}) like '%data infrastructure%'   then 'Data Engineering'
        when lower({{ job_title_col }}) like '%data warehouse%'        then 'Data Engineering'
        when lower({{ job_title_col }}) like '%big data%'              then 'Data Engineering'
        when lower({{ job_title_col }}) like '%etl%'                   then 'Data Engineering'
        when lower({{ job_title_col }}) like '%databricks%'            then 'Data Engineering'
        when lower({{ job_title_col }}) like '%lakehouse%'             then 'Data Engineering'
        when lower({{ job_title_col }}) like '%spark engineer%'        then 'Data Engineering'
        when lower({{ job_title_col }}) like '%spark developer%'       then 'Data Engineering'
        when lower({{ job_title_col }}) like '%airflow%'               then 'Data Engineering'
        when lower({{ job_title_col }}) like '%kafka engineer%'        then 'Data Engineering'
        when lower({{ job_title_col }}) like '%kafka developer%'       then 'Data Engineering'
        when lower({{ job_title_col }}) like '% dbt %'                 then 'Data Engineering'
        when lower({{ job_title_col }}) like '%dbt developer%'         then 'Data Engineering'
        when lower({{ job_title_col }}) like '%dbt engineer%'          then 'Data Engineering'
        -- English patterns — Data Analytics
        when lower({{ job_title_col }}) like '%data analyst%'          then 'Data Analytics'
        when lower({{ job_title_col }}) like '%business analyst%'      then 'Data Analytics'
        when lower({{ job_title_col }}) like '%bi %'                   then 'Data Analytics'
        when lower({{ job_title_col }}) like '%power bi%'              then 'Data Analytics'
        when lower({{ job_title_col }}) like '%tableau%'               then 'Data Analytics'
        -- English patterns — Data Science
        when lower({{ job_title_col }}) like '%data scientist%'        then 'Data Science'
        when lower({{ job_title_col }}) like '%research scientist%'    then 'Data Science'
        -- English patterns — ML / AI Engineering
        when lower({{ job_title_col }}) like '%machine learning%'      then 'ML / AI Engineering'
        when lower({{ job_title_col }}) like '%ml engineer%'           then 'ML / AI Engineering'
        when lower({{ job_title_col }}) like '%ai engineer%'           then 'ML / AI Engineering'
        when lower({{ job_title_col }}) like '%nlp%'                   then 'ML / AI Engineering'
        -- English patterns — Database Administration
        when lower({{ job_title_col }}) like '%database%'              then 'Database Administration'
        when lower({{ job_title_col }}) like '%dba%'                   then 'Database Administration'
        -- Slovak patterns (profesia.sk titles)
        when lower({{ job_title_col }}) like '%dátový inžinier%'       then 'Data Engineering'
        when lower({{ job_title_col }}) like '%datový inžinier%'       then 'Data Engineering'
        when lower({{ job_title_col }}) like '%inžinier dát%'          then 'Data Engineering'
        when lower({{ job_title_col }}) like '%dátová platforma%'      then 'Data Engineering'
        when lower({{ job_title_col }}) like '%dátový sklad%'          then 'Data Engineering'
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
