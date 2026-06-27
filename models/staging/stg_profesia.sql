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
        -- location: flag remote, extract city as first comma-delimited token
        case
            when lower(location) like '%z domu%'
              or lower(location) like '%home office%' then true
            else false
        end                                                                  as is_remote,

        trim(split(location, ',')[safe_offset(0)])                           as location_city,

        -- salary: EUR-only (drops CZK and other currencies); NULLs kept for unpublished salaries
        case
            when salary_text like '%EUR/mesiac%' then 'monthly'
            when salary_text like '%EUR/hod.%'   then 'hourly'
        end                                                                  as salary_period,

        -- strip thousand-separator spaces and comma decimals before extracting integers
        safe_cast(
            regexp_extract(
                regexp_replace(
                    regexp_replace(salary_text, r'(\d)\s(\d)', r'\1\2'),
                    r',\d+', ''
                ),
                r'(\d+)'
            ) as int64
        )                                                                    as salary_eur_min,

        safe_cast(
            regexp_extract(
                regexp_replace(
                    regexp_replace(salary_text, r'(\d)\s(\d)', r'\1\2'),
                    r',\d+', ''
                ),
                r'\d+\s*-\s*(\d+)'
            ) as int64
        )                                                                    as salary_eur_max,

        {{ classify_role_family('title') }}                                 as role_family,
        {{ classify_seniority_from_title('title') }}                      as seniority,

        _scraped_at,
        date(_scraped_at)                                                    as scraped_date,
        extract(year from date(_scraped_at))                                 as work_year

    from deduped
    where offer_id is not null
      and {{ is_it_job('lower(title)') }}
)

select * from cleaned
where role_family != 'Other'
