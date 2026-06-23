with salary as (
    select * from {{ ref('mart_salary_by_region') }}
)

select
    role_family,
    seniority_tier,
    sum(respondent_count)                                                           as total_respondents,
    round(
        sum(avg_salary_usd * respondent_count) / nullif(sum(respondent_count), 0), 0
    )                                                                               as weighted_avg_salary_usd,
    min(median_salary_usd)                                                          as min_country_median_usd,
    max(median_salary_usd)                                                          as max_country_median_usd,
    round(max(median_salary_usd) - min(median_salary_usd), 0)                       as salary_spread_usd
from salary
group by 1, 2
order by role_family,
    case seniority_tier
        when 'Junior'       then 1
        when 'Mid'          then 2
        when 'Senior'       then 3
        when 'Staff / Lead' then 4
        else                     9
    end
