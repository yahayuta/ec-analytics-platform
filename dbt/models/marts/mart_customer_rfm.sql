-- RFM segmentation (Recency / Frequency / Monetary) for CRM targeting.
-- Recency is measured against the latest order date in the dataset so the
-- result is reproducible regardless of when the model runs.
with base as (
    select
        customer_id,
        last_ordered_on,
        order_count,
        lifetime_revenue
    from {{ ref('dim_customers') }}
    where order_count > 0
),

reference_date as (
    select max(last_ordered_on) as as_of from base
),

scored as (
    select
        b.customer_id,
        {{ dbt.datediff('b.last_ordered_on', 'r.as_of', 'day') }} as recency_days,
        b.order_count      as frequency,
        b.lifetime_revenue as monetary,
        ntile(5) over (order by {{ dbt.datediff('b.last_ordered_on', 'r.as_of', 'day') }} desc) as r_score,
        ntile(5) over (order by b.order_count)       as f_score,
        ntile(5) over (order by b.lifetime_revenue)  as m_score
    from base as b
    cross join reference_date as r
)

select
    *,
    case
        when r_score >= 4 and f_score >= 4 then 'champions'
        when r_score >= 3 and f_score >= 3 then 'loyal'
        when r_score >= 4 and f_score <= 2 then 'new_or_promising'
        when r_score <= 2 and f_score >= 3 then 'at_risk'
        else 'hibernating'
    end as segment
from scored
