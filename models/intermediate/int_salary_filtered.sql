with classified as (
    select * from {{ ref('int_roles_classified') }}
),

with_bounds as (
    select
        *,
        percentile_cont(comp_yearly_usd, 0.01) over (partition by country_code) as p01_salary,
        percentile_cont(comp_yearly_usd, 0.99) over (partition by country_code) as p99_salary
    from classified
)

select
    response_id,
    country_code,
    country_name,
    eu_region,
    eu_member,
    employment_type_code,
    company_size,
    remote_ratio,
    company_country_code,
    job_title_raw,
    role_family,
    seniority_tier,
    experience_level_code,
    comp_yearly_usd,
    currency_raw,
    work_year,
    _bq_loaded_at

from with_bounds
where comp_yearly_usd between p01_salary and p99_salary
