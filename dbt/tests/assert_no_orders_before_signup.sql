-- A customer cannot order before signing up.
select o.order_id, o.ordered_on, c.signed_up_on
from {{ ref('stg_orders') }} as o
inner join {{ ref('stg_customers') }} as c on o.customer_id = c.customer_id
where o.ordered_on < c.signed_up_on
