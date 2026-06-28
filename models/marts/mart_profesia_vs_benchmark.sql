with listings as (
    select * from {{ ref('fact_job_listings') }}
    where role_family != 'Other'
      and salary_yearly_eur_min is not null
),

-- seniority-level benchmark (precise)
benchmark_seniority as (
    select
        role_family,
        seniority_tier,
        weighted_avg_salary_usd     as eu_avg_salary_usd,
        min_country_median_usd      as eu_min_country_median_usd,
        max_country_median_usd      as eu_max_country_median_usd,
        total_respondents           as eu_respondent_count
    from {{ ref('mart_job_market_kpis') }}
),

-- role-level fallback (when seniority combo has no benchmark row)
benchmark_role as (
    select
        role_family,
        round(
            sum(weighted_avg_salary_usd * total_respondents) / nullif(sum(total_respondents), 0), 0
        )                               as eu_avg_salary_usd,
        min(min_country_median_usd)     as eu_min_country_median_usd,
        max(max_country_median_usd)     as eu_max_country_median_usd,
        sum(total_respondents)          as eu_respondent_count
    from {{ ref('mart_job_market_kpis') }}
    group by 1
),

final as (
    select
        l.listing_id,
        l.offer_id,
        l.job_title_raw,
        l.role_family,
        l.seniority,
        l.company_name,
        l.location_city,
        l.is_remote,
        l.salary_yearly_eur_min,
        l.salary_yearly_eur_max,
        l.salary_yearly_usd_min,
        l.salary_yearly_usd_max,
        l.scraped_date,

        -- prefer seniority-matched benchmark, fall back to role-level
        coalesce(bs.eu_avg_salary_usd,          br.eu_avg_salary_usd)          as eu_avg_salary_usd,
        coalesce(bs.eu_min_country_median_usd,  br.eu_min_country_median_usd)  as eu_min_country_median_usd,
        coalesce(bs.eu_max_country_median_usd,  br.eu_max_country_median_usd)  as eu_max_country_median_usd,
        coalesce(bs.eu_respondent_count,        br.eu_respondent_count)        as eu_respondent_count,
        bs.eu_avg_salary_usd is not null                                        as benchmark_is_seniority_matched
    from listings l
    left join benchmark_seniority bs
        on  l.role_family = bs.role_family
        and l.seniority   = bs.seniority_tier
    left join benchmark_role br
        on l.role_family = br.role_family
)

select * from final
