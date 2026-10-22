{{ config(materialized='table') }}

with pix_payments as (
    select
        payment_id,
        purchased_at,
        amount_brl,
        payment_type,
        description,
        comments,
        tipo_gasto,
        category_name,
        subcategory_name1,
        subcategory_name2,
        is_internal_transfer,
        is_payment_transaction
    from {{ ref('stg_pix_payments') }}
),

card_payments as (
    select
        payment_id,
        purchased_at,
        amount_brl,
        payment_type,
        description,
        comments,
        tipo_gasto,
        category_name,
        subcategory_name1,
        subcategory_name2,
        is_internal_transfer,
        is_payment_transaction
    from {{ ref('stg_card_payments') }}
),

unified as (
    select * from pix_payments
    union all
    select * from card_payments
)

select
    payment_id,
    purchased_at,
    amount_brl,
    payment_type,
    description,
    comments,
    
    lower(tipo_gasto) as tipo_gasto,
    initcap(category_name) as category_name,
    initcap(subcategory_name1) as subcategory_name1,
    initcap(subcategory_name2) as subcategory_name2,
    
    is_internal_transfer,
    is_payment_transaction
from unified
where is_payment_transaction = true
  and is_internal_transfer = false
order by purchased_at desc