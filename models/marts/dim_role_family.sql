with role_families as (
    select distinct role_family
    from {{ ref('int_roles_classified') }}
    where role_family != 'Other'
)

select
    {{ dbt_utils.generate_surrogate_key(['role_family']) }}  as role_family_id,
    role_family,
    case role_family
        when 'Data Engineering'        then 1
        when 'Data Science'            then 2
        when 'Data Analytics'          then 3
        when 'ML / AI Engineering'     then 4
        when 'Database Administration' then 5
        else                                9
    end                                    as display_order
from role_families
