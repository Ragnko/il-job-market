with stg as (
    select * from {{ ref('stg_survey_responses') }}
),

european_countries as (
    select country_code, country_name, eu_region, eu_member
    from {{ ref('european_countries') }}
),

classified as (
    select
        stg.response_id,
        stg.country_code,
        ec.country_name,
        ec.eu_region,
        ec.eu_member,
        stg.employment_type_code,
        stg.company_size,
        stg.remote_ratio,
        stg.company_country_code,
        stg.job_title_raw,
        stg.experience_level_code,
        stg.comp_yearly_usd,
        stg.currency_raw,
        stg.work_year,
        stg._bq_loaded_at,

        {{ classify_role_family('stg.job_title_raw') }}         as role_family,
        {{ classify_seniority('stg.experience_level_code') }}   as seniority_tier

    from stg
    inner join european_countries ec using (country_code)
)

select * from classified
where role_family != 'Other'
