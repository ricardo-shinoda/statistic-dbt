{{ config(materialized='table') }}

with staging as (
    select * from {{ ref('stg_card_payments') }}
)

select
    original_category as category,
    count(*) as total_transactions,
    sum(amount_brl) as total_acumulated_amount
from staging
group by 1