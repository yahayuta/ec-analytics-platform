select
    customer_id,
    {{ clean_text('email') }}          as email,
    prefecture,
    cast(signed_up_on as date)         as signed_up_on
from {{ ref('raw_customers') }}
