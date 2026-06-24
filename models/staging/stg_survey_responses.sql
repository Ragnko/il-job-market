with source as (
    select * from {{ source('raw', 'ds_salaries') }}
),

renamed as (
    select
        {{ dbt_utils.generate_surrogate_key([
            'row_index', 'work_year', 'experience_level', 'employment_type',
            'job_title', 'salary', 'salary_currency',
            'employee_residence', 'remote_ratio', 'company_location', 'company_size'
        ]) }}                                                        as response_id,

        -- geography
        employee_residence                                           as country_code,
        company_location                                             as company_country_code,

        -- employment
        employment_type                                              as employment_type_code,
        company_size                                                 as company_size,
        safe_cast(remote_ratio as int64)                             as remote_ratio,

        -- role & seniority
        job_title                                                    as job_title_raw,
        experience_level                                             as experience_level_code,

        -- compensation (already in USD)
        safe_cast(salary_in_usd as float64)                         as comp_yearly_usd,
        salary_currency                                              as currency_raw,

        -- time dimension
        safe_cast(work_year as int64)                               as work_year,

        -- metadata
        _bq_loaded_at

    from source
    where
        salary_in_usd is not null
        and safe_cast(salary_in_usd as float64) between 10000 and 500000
        and job_title is not null
)

select * from renamed
