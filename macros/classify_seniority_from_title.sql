{% macro classify_seniority_from_title(job_title_col) %}
    case
        -- Staff / Lead checked first so "senior lead" resolves to Lead, not Senior
        when lower({{ job_title_col }}) like '%lead%'          then 'Staff / Lead'
        when lower({{ job_title_col }}) like '%principal%'     then 'Staff / Lead'
        when lower({{ job_title_col }}) like '%staff%'         then 'Staff / Lead'
        when lower({{ job_title_col }}) like '%head of%'       then 'Staff / Lead'
        when lower({{ job_title_col }}) like '% head %'        then 'Staff / Lead'
        when lower({{ job_title_col }}) like '%manager%'       then 'Staff / Lead'
        when lower({{ job_title_col }}) like '%vedúci%'        then 'Staff / Lead'
        when lower({{ job_title_col }}) like '%hlavný%'        then 'Staff / Lead'
        when lower({{ job_title_col }}) like '%senior%'        then 'Senior'
        when lower({{ job_title_col }}) like '%junior%'        then 'Junior'
        when lower({{ job_title_col }}) like '%trainee%'       then 'Junior'
        when lower({{ job_title_col }}) like '%absolvent%'     then 'Junior'
        when lower({{ job_title_col }}) like '%stáž%'          then 'Junior'
        when lower({{ job_title_col }}) like '%intern%'        then 'Junior'
        else                                                        'Mid'
    end
{% endmacro %}
