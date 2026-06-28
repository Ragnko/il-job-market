with listings as (
    select * from {{ ref('fact_job_listings') }}
    where role_family != 'Other'
      and salary_yearly_eur_min is not null
),

benchmark as (
    select
        role_family,
        seniority_tier,
        weighted_avg_salary_usd     as eu_avg_salary_usd,
        min_country_median_usd      as eu_min_country_median_usd,
        max_country_median_usd      as eu_max_country_median_usd,
        total_respondents           as eu_respondent_count
    from {{ ref('mart_job_market_kpis') }}
),

benchmark_role as (
    select
        role_family,
        sum(weighted_avg_salary_usd * total_respondents)
            / nullif(sum(total_respondents), 0)     as eu_avg_salary_usd_role,
        min(min_country_median_usd)                 as eu_min_country_median_usd_role,
        max(max_country_median_usd)                 as eu_max_country_median_usd_role,
        sum(total_respondents)                      as eu_respondent_count_role
    from {{ ref('mart_job_market_kpis') }}
    group by role_family
),

final as (
    select
        l.listing_id,
        l.offer_id,
        l.listing_url,
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
        coalesce(b.eu_avg_salary_usd,          br.eu_avg_salary_usd_role)          as eu_avg_salary_usd,
        coalesce(b.eu_min_country_median_usd,  br.eu_min_country_median_usd_role)  as eu_min_country_median_usd,
        coalesce(b.eu_max_country_median_usd,  br.eu_max_country_median_usd_role)  as eu_max_country_median_usd,
        coalesce(b.eu_respondent_count,        br.eu_respondent_count_role)        as eu_respondent_count

    from listings l
    left join benchmark b
        on  l.role_family = b.role_family
        and l.seniority = b.seniority_tier
    left join benchmark_role br
        on  l.role_family = br.role_family
)

select * from final
where eu_respondent_count is not null

