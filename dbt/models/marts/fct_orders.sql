-- One row per order with revenue and margin. Only completed orders count
-- towards net revenue; cancelled and returned orders are kept for analysis.
with lines as (
    select
        order_id,
        count(*)          as line_count,
        sum(quantity)     as item_quantity,
        sum(line_amount)  as merchandise_amount,
        sum(line_margin)  as gross_margin
    from {{ ref('int_order_lines_enriched') }}
    group by order_id
)

select
    o.order_id,
    o.customer_id,
    o.channel,
    o.status,
    o.ordered_at,
    o.ordered_on,
    l.line_count,
    l.item_quantity,
    l.merchandise_amount,
    o.shipping_fee,
    l.merchandise_amount + o.shipping_fee                         as order_amount,
    l.gross_margin,
    case when o.status = 'completed' then l.merchandise_amount else 0 end as net_revenue,
    o.status = 'completed'                                         as is_completed
from {{ ref('stg_orders') }} as o
inner join lines as l on o.order_id = l.order_id
