-- Returns rows where a country/role/seniority segment has a suspiciously low
-- median salary for Europe (< $15k USD). Any result means the test fails.
-- Segments with < 5 respondents are already suppressed in the mart.
select
    country_name,
    role_family,
    seniority_tier,
    median_salary_usd,
    respondent_count
from {{ ref('mart_salary_by_region') }}
where median_salary_usd < 15000
