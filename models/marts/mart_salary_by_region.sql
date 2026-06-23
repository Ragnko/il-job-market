with fact as (
    select * from {{ ref('fact_compensation') }}
),

country as (
    select * from {{ ref('dim_country') }}
),

aggregated as (
    select
        c.eu_region,
        fact.country_name,
        fact.role_family,
        fact.seniority_tier,
        count(*)                                                             as respondent_count,
        round(avg(fact.comp_yearly_usd), 0)                                  as avg_salary_usd,
        round(approx_quantiles(fact.comp_yearly_usd, 100)[offset(50)], 0)    as median_salary_usd,
        round(approx_quantiles(fact.comp_yearly_usd, 100)[offset(25)], 0)    as p25_salary_usd,
        round(approx_quantiles(fact.comp_yearly_usd, 100)[offset(75)], 0)    as p75_salary_usd
    from fact
    inner join country using (country_name)
    group by 1, 2, 3, 4
)

select * from aggregated
where respondent_count >= 5
