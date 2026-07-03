{{ config(materialized='table') }}

select 
    payment_id,
    amount_brl,
    purchased_at,
    payment_type,
    description,
    comments,
    tipo_gasto,
    grupo,
    category_name,
    subcategory_name,
    is_internal_transfer,
    is_payment_transaction
from {{ ref('stg_pix_payments') }}

union all

select 
    payment_id,
    amount_brl,
    purchased_at,
    payment_type,
    description,
    comments,
    tipo_gasto,
    grupo,
    category_name,
    subcategory_name,
    is_internal_transfer,
    is_payment_transaction
from {{ ref('stg_card_payments') }}