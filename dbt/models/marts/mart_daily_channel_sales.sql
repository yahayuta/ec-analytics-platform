-- Daily KPIs per sales channel: the main table behind the Looker Studio dashboard.
select
    ordered_on,
    channel,
    count(*)                                              as orders,
    sum(case when is_completed then 1 else 0 end)         as completed_orders,
    sum(case when status = 'cancelled' then 1 else 0 end) as cancelled_orders,
    sum(case when status = 'returned' then 1 else 0 end)  as returned_orders,
    sum(net_revenue)                                      as net_revenue,
    sum(case when is_completed then gross_margin else 0 end) as gross_margin,
    sum(case when is_completed then net_revenue end)
        / nullif(sum(case when is_completed then 1 else 0 end), 0) as average_order_value
from {{ ref('fct_orders') }}
group by ordered_on, channel
