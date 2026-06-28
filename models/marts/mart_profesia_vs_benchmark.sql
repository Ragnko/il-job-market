with listings as (
    select * from {{ ref('fact_job_listings') }}
    where role_family in ('Data Engineering', 'Data Science')
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

        b.eu_avg_salary_usd,
        b.eu_min_country_median_usd,
        b.eu_max_country_median_usd,
        b.eu_respondent_count
    from listings l
    left join benchmark b
        on  l.role_family   = b.role_family
        and l.seniority     = b.seniority_tier
)

select * from final
