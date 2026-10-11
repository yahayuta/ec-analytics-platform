-- Order lines joined with order header and product attributes,
-- with gross margin calculated per line.
select
    i.order_item_id,
    i.order_id,
    o.customer_id,
    o.channel,
    o.status,
    o.ordered_at,
    o.ordered_on,
    i.product_id,
    p.category,
    i.quantity,
    i.unit_price,
    i.line_amount,
    i.quantity * p.unit_cost              as line_cost,
    i.line_amount - i.quantity * p.unit_cost as line_margin
from {{ ref('stg_order_items') }} as i
inner join {{ ref('stg_orders') }}   as o on i.order_id = o.order_id
inner join {{ ref('stg_products') }} as p on i.product_id = p.product_id
