{{
    config(
        materialized='incremental',
        unique_key='response_id',
        incremental_strategy='merge'
    )
}}

with source as (
    select * from {{ ref('int_salary_filtered') }}
)

select
    response_id,
    country_name,
    role_family,
    seniority_tier,
    employment_type,
    org_size,
    industry,
    education_level,
    comp_yearly_usd,
    years_code_pro,
    years_code_total,
    languages_used,
    databases_used,
    platforms_used,
    _bq_loaded_at

from source

{% if is_incremental() %}
    -- on incremental runs, only process rows newer than what's already in the table;
    -- for a live feed this would be a posting date; for the SO survey it covers reruns
    where _bq_loaded_at > (select max(_bq_loaded_at) from {{ this }})
{% endif %}
