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

final as (
    select
        listing_id,
        offer_id,
        job_title_raw,
        company_name,
        location_city,
        location_raw,
        is_remote,
        salary_period,
        salary_eur_min,
        salary_eur_max,

        -- normalise hourly to monthly for comparison (approx 160h/month)
        case
            when salary_period = 'monthly' then salary_eur_min
            when salary_period = 'hourly'  then round(salary_eur_min * 160, 0)
        end                                as salary_monthly_eur_min,

        case
            when salary_period = 'monthly' then salary_eur_max
            when salary_period = 'hourly'  then round(salary_eur_max * 160, 0)
        end                                as salary_monthly_eur_max,

        salary_text_raw,
        contact_name_hashed,
        listing_url,
        scraped_date,
        _scraped_at

    from source
)

select * from final

{% if is_incremental() %}
    where _scraped_at > (select max(_scraped_at) from {{ this }})
{% endif %}
