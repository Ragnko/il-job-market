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
    country_code,
    country_name,
    eu_region,
    eu_member,
    role_family,
    seniority_tier,
    employment_type_code,
    company_size,
    remote_ratio,
    comp_yearly_usd,
    work_year,
    _bq_loaded_at

from source

{% if is_incremental() %}
    where _bq_loaded_at > (select max(_bq_loaded_at) from {{ this }})
{% endif %}
