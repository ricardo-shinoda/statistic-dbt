{{ config(materialized='table') }}

select
    payment_id,
    amount_brl,
    purchased_at,
    description,
    comments,
    payment_type,
    category_clean as category_name,
    subcategory_clean as subcategory_name
from {{ ref('payments') }}