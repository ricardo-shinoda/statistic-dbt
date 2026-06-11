{{ config(materialized='table') }}

select
    payment_id,
    amount_brl,
    purchased_at,
    invoice_name,
    description,
    comments,
    payment_type,
    category_clean as category_name,
    subcategory_clean as subcategory_name,
    is_internal_transfer,
    is_payment_transaction
from {{ ref('payments') }}