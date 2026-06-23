with source as (
    select * from {{ source('raw', 'so_survey_2024') }}
),

renamed as (
    select
        {{ dbt_utils.generate_surrogate_key(['ResponseId']) }}      as response_id,

        -- geography
        Country                                                      as country_name,

        -- employment
        Employment                                                   as employment_type,
        OrgSize                                                      as org_size,
        Industry                                                     as industry,

        -- role
        DevType                                                      as dev_type_raw,

        -- seniority signals
        safe_cast(nullif(YearsCodePro, 'NA') as int64)              as years_code_pro,
        safe_cast(nullif(YearsCode, 'NA') as int64)                 as years_code_total,

        -- education
        EdLevel                                                      as education_level,

        -- compensation
        safe_cast(ConvertedCompYearly as float64)                    as comp_yearly_usd,
        Currency                                                     as currency_raw,

        -- tech stack signals (useful for "what-if" extensions)
        LanguageHaveWorkedWith                                       as languages_used,
        DatabaseHaveWorkedWith                                       as databases_used,
        PlatformHaveWorkedWith                                       as platforms_used,

        -- metadata
        _bq_loaded_at

    from source
    where
        ConvertedCompYearly is not null
        and safe_cast(ConvertedCompYearly as float64) between 10000 and 500000
        and DevType is not null
)

select * from renamed
