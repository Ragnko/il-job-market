with source as (
    select * from {{ source('raw', 'so_survey') }}
),

renamed as (
    select
        {{ dbt_utils.generate_surrogate_key(['ResponseId']) }}       as response_id,

        -- geography: normalize long country names to match european_countries seed
        case Country
            when 'United Kingdom of Great Britain and Northern Ireland' then 'United Kingdom'
            when 'Republic of Moldova'                                  then 'Moldova'
            else Country
        end                                                          as country_name,

        -- role (semicolon-separated multi-select — macro handles pattern matching)
        DevType                                                      as job_title_raw,

        -- seniority: map years of professional work experience to EN/MI/SE/EX codes
        -- 2025 survey uses numeric WorkExp (replacing the string YearsCodePro from 2024)
        case
            when WorkExp < 3  then 'EN'
            when WorkExp < 6  then 'MI'
            when WorkExp < 10 then 'SE'
            when WorkExp >= 10 then 'EX'
            else null
        end                                                          as experience_level_code,

        -- compensation (already in USD)
        safe_cast(ConvertedCompYearly as float64)                    as comp_yearly_usd,
        Currency                                                     as currency_raw,

        -- employment
        Employment                                                   as employment_type_code,

        -- time dimension
        2025                                                         as work_year,

        -- metadata
        _bq_loaded_at

    from source
    where
        ConvertedCompYearly is not null
        and safe_cast(ConvertedCompYearly as float64) between 10000 and 500000
        and DevType is not null
)

select * from renamed
