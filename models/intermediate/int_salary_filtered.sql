with classified as (
    select * from {{ ref('int_roles_classified') }}
),

-- compute country-level bounds as window functions first
with_bounds as (
    select
        *,
        percentile_cont(comp_yearly_usd, 0.01) over (partition by country_name) as p01_salary,
        percentile_cont(comp_yearly_usd, 0.99) over (partition by country_name) as p99_salary
    from classified
)

select
    response_id,
    country_name,
    employment_type,
    org_size,
    industry,
    dev_type_raw,
    role_family,
    seniority_tier,
    years_code_pro,
    years_code_total,
    education_level,
    comp_yearly_usd,
    currency_raw,
    languages_used,
    databases_used,
    platforms_used,
    _bq_loaded_at

from with_bounds
where comp_yearly_usd between p01_salary and p99_salary
