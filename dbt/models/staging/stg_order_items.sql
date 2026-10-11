select
    order_item_id,
    order_id,
    product_id,
    cast(quantity as integer)                    as quantity,
    cast(unit_price as integer)                  as unit_price,
    cast(quantity as integer) * cast(unit_price as integer) as line_amount
from {{ ref('raw_order_items') }}
