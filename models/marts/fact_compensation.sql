{{
    config(
        materialized='incremental',
        unique_key='response_id',
        incremental_strategy='merge'
    )
}}

with source as (
    select * from {{ ref('int_salary_filtered') }}
),

fx as (
    select * from {{ ref('exchange_rates') }}
)

select
    s.response_id,
    s.country_code,
    s.country_name,
    s.eu_region,
    s.eu_member,
    s.role_family,
    s.seniority_tier,
    s.employment_type_code,
    s.comp_yearly_usd,
    round(s.comp_yearly_usd * fx.usd_to_eur, 0) as comp_yearly_eur,
    s.work_year,
    s._bq_loaded_at

from source s
left join fx on fx.year = s.work_year

{% if is_incremental() %}
    where s._bq_loaded_at > (select max(_bq_loaded_at) from {{ this }})
{% endif %}
