-- Revenue in the order fact must reconcile with the sum of its order lines.
-- Returns rows (= failure) if any order differs.
with lines as (
    select order_id, sum(line_amount) as line_total
    from {{ ref('stg_order_items') }}
    group by order_id
)

select f.order_id, f.merchandise_amount, l.line_total
from {{ ref('fct_orders') }} as f
inner join lines as l on f.order_id = l.order_id
where f.merchandise_amount <> l.line_total
