with orders as (
    select
        customer_id,
        count(*)                                   as order_count,
        sum(net_revenue)                           as lifetime_revenue,
        min(ordered_on)                            as first_ordered_on,
        max(ordered_on)                            as last_ordered_on
    from {{ ref('fct_orders') }}
    where is_completed
    group by customer_id
)

select
    c.customer_id,
    c.prefecture,
    c.signed_up_on,
    coalesce(o.order_count, 0)       as order_count,
    coalesce(o.lifetime_revenue, 0)  as lifetime_revenue,
    o.first_ordered_on,
    o.last_ordered_on,
    coalesce(o.order_count, 0) >= 2  as is_repeat_customer
from {{ ref('stg_customers') }} as c
left join orders as o on c.customer_id = o.customer_id
