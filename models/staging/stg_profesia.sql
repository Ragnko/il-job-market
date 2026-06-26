with source as (
    select * from {{ source('raw', 'profesia_listings') }}
),

-- deduplicate: keep the most recent scrape per offer_id
deduped as (
    select *
    from source
    qualify row_number() over (partition by offer_id order by _scraped_at desc) = 1
),

cleaned as (
    select
        -- surrogate key: one row per unique listing
        {{ dbt_utils.generate_surrogate_key(['offer_id']) }}                 as listing_id,

        safe_cast(offer_id as int64)                                         as offer_id,
        title                                                                as job_title_raw,
        company                                                              as company_name,
        url                                                                  as listing_url,

        -- location: flag remote, extract city as first comma-delimited token
        case
            when lower(location) like '%z domu%'
              or lower(location) like '%home office%' then true
            else false
        end                                                                  as is_remote,

        trim(split(location, ',')[safe_offset(0)])                           as location_city,
        location                                                             as location_raw,

        -- salary: strip thousand-separator spaces, then extract min/max and period
        case
            when salary_text like '%/mesiac%' then 'monthly'
            when salary_text like '%/hod.%'   then 'hourly'
        end                                                                  as salary_period,

        safe_cast(
            regexp_extract(
                regexp_replace(salary_text, r'(\d)\s(\d)', r'\1\2'),
                r'(\d{3,})'
            ) as int64
        )                                                                    as salary_eur_min,

        safe_cast(
            regexp_extract(
                regexp_replace(salary_text, r'(\d)\s(\d)', r'\1\2'),
                r'\d+\s*-\s*(\d{3,})'
            ) as int64
        )                                                                    as salary_eur_max,

        salary_text                                                          as salary_text_raw,

        -- PII handling: hash contact_name for pseudonymisation, suppress raw value
        case
            when contact_name is not null
            then to_hex(md5(trim(contact_name)))
            else null
        end                                                                  as contact_name_hashed,

        -- raw name intentionally excluded from this model — not passed downstream
        -- retained only in raw.profesia_listings under access control

        _scraped_at,
        date(_scraped_at)                                                    as scraped_date

    from deduped
    where offer_id is not null
)

select * from cleaned
