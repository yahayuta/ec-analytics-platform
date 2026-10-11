-- One row per order. Removes duplicate rows caused by re-ingestion and
-- normalises channel names (" MARKETPLACE_A" -> "marketplace_a").
with source as (
    select * from {{ ref('raw_orders') }}
),

deduplicated as (
    select *
    from source
    qualify row_number() over (partition by order_id order by ordered_at) = 1
)

select
    order_id,
    customer_id,
    {{ clean_text('channel') }}          as channel,
    cast(ordered_at as timestamp)        as ordered_at,
    cast(cast(ordered_at as timestamp) as date) as ordered_on,
    {{ clean_text('status') }}           as status,
    cast(shipping_fee as integer)        as shipping_fee
from deduplicated
