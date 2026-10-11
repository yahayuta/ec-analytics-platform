select
    product_id,
    product_name,
    category,
    cast(list_price as integer) as list_price,
    cast(unit_cost as integer)  as unit_cost
from {{ ref('raw_products') }}
