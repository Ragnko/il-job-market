with stg as (
    select * from {{ ref('stg_survey_responses') }}
),

european_countries as (
    select country_name
    from {{ ref('european_countries') }}
),

classified as (
    select
        stg.response_id,
        stg.country_name,
        stg.employment_type,
        stg.org_size,
        stg.industry,
        stg.dev_type_raw,
        stg.years_code_pro,
        stg.years_code_total,
        stg.education_level,
        stg.comp_yearly_usd,
        stg.currency_raw,
        stg.languages_used,
        stg.databases_used,
        stg.platforms_used,
        stg._bq_loaded_at,

        {{ classify_role_family('stg.dev_type_raw') }}  as role_family,
        {{ classify_seniority('stg.years_code_pro') }}  as seniority_tier

    from stg
    -- restrict to European respondents by joining to the seed
    inner join european_countries using (country_name)
)

select * from classified
where role_family != 'Other'
