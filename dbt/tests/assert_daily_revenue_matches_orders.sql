-- The daily channel mart must add up to the same net revenue as the order fact.
select *
from (
    select
        (select sum(net_revenue) from {{ ref('mart_daily_channel_sales') }}) as mart_total,
        (select sum(net_revenue) from {{ ref('fct_orders') }})               as fact_total
) as t
where mart_total <> fact_total
