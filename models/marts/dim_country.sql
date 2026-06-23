select
    country_name,
    eu_region,
    cast(eu_member as bool)  as eu_member,
    typical_currency
from {{ ref('european_countries') }}
