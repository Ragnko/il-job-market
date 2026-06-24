with so_survey as (
    select * from {{ ref('stg_so_survey') }}
),

european_countries as (
    select country_code, country_name, eu_region, eu_member
    from {{ ref('european_countries') }}
),

classified as (
    select
        stg.response_id,
        ec.country_code,
        stg.country_name,
        ec.eu_region,
        ec.eu_member,
        stg.employment_type_code,
        stg.job_title_raw,
        stg.experience_level_code,
        stg.comp_yearly_usd,
        stg.currency_raw,
        stg.work_year,
        stg._bq_loaded_at,
        'so_survey'                                                  as source,

        {{ classify_role_family('stg.job_title_raw') }}              as role_family,
        {{ classify_seniority('stg.experience_level_code') }}        as seniority_tier

    from so_survey stg
    inner join european_countries ec using (country_name)
)

select * from classified
where role_family != 'Other'
