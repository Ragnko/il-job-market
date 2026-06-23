select
    seniority_tier,
    case seniority_tier
        when 'Junior'       then 1
        when 'Mid'          then 2
        when 'Senior'       then 3
        when 'Staff / Lead' then 4
        else                     9
    end                         as display_order,
    case seniority_tier
        when 'Junior'       then '0–2 yrs'
        when 'Mid'          then '3–5 yrs'
        when 'Senior'       then '6–9 yrs'
        when 'Staff / Lead' then '10+ yrs'
        else                     'Not reported'
    end                         as years_range
from unnest([
    'Junior',
    'Mid',
    'Senior',
    'Staff / Lead',
    'Unknown'
]) as seniority_tier
