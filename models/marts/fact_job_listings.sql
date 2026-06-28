{{
    config(
        materialized='incremental',
        unique_key='listing_id',
        incremental_strategy='merge'
    )
}}

with source as (
    select * from {{ ref('stg_profesia') }}
),

fx as (
    select * from {{ ref('exchange_rates') }}
),

final as (
    select
        s.listing_id,
        s.offer_id,
        s.listing_url,
        s.job_title_raw,
        s.role_family,
        s.seniority,
        s.company_name,
        s.location_city,
        s.is_remote,
        s.salary_period,
        s.salary_eur_min,
        s.salary_eur_max,

        -- normalise hourly to monthly for comparison (approx 160h/month)
        case
            when s.salary_period = 'monthly' then s.salary_eur_min
            when s.salary_period = 'hourly'  then round(s.salary_eur_min * 160, 0)
        end                                as salary_monthly_eur_min,

        case
            when s.salary_period = 'monthly' then s.salary_eur_max
            when s.salary_period = 'hourly'  then round(s.salary_eur_max * 160, 0)
        end                                as salary_monthly_eur_max,

        -- annualised salary in EUR
        case
            when s.salary_period = 'monthly' then s.salary_eur_min * 12
            when s.salary_period = 'hourly'  then round(s.salary_eur_min * 160, 0) * 12
        end                                as salary_yearly_eur_min,

        case
            when s.salary_period = 'monthly' then s.salary_eur_max * 12
            when s.salary_period = 'hourly'  then round(s.salary_eur_max * 160, 0) * 12
        end                                as salary_yearly_eur_max,

        -- annualised salary converted to USD via yearly exchange rate
        case
            when s.salary_period = 'monthly' then round(s.salary_eur_min * 12 * fx.eur_to_usd, 0)
            when s.salary_period = 'hourly'  then round(s.salary_eur_min * 160 * 12 * fx.eur_to_usd, 0)
        end                                as salary_yearly_usd_min,

        case
            when s.salary_period = 'monthly' then round(s.salary_eur_max * 12 * fx.eur_to_usd, 0)
            when s.salary_period = 'hourly'  then round(s.salary_eur_max * 160 * 12 * fx.eur_to_usd, 0)
        end                                as salary_yearly_usd_max,

        s.work_year,
        s.scraped_date,
        s._scraped_at

    from source s
    left join fx on fx.year = s.work_year
)

select * from final

{% if is_incremental() %}
    where _scraped_at > (select max(_scraped_at) from {{ this }})
{% endif %}
