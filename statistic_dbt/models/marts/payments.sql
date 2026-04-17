{{ config(materialized='table') }}

with card_payments as (
    select 
        payment_id,
        amount_brl,
        purchased_at,
        description,
        comments,
        category_name,
        payment_type
    from {{ ref('stg_card_payments') }}
),

pix_payments as (
    select 
        payment_id,
        amount_brl,
        purchased_at,
        description,
        comments,
        category_name,
        payment_type
    from {{ ref('stg_pix_payments') }}
),

unioned_payments as (
    select * from card_payments
    union all
    select * from pix_payments
),

mapping as (
    select * from {{ ref('category_mapping') }}
)

select
    p.*,
    coalesce(
        (select m.categoria 
         from mapping m 
         where upper(p.description) like '%' || upper(m.original) || '%'
         limit 1), 
        p.category_name, 
        'TBD'
    ) as category_clean,
    
    coalesce(
        (select m.subcategoria 
         from mapping m 
         where upper(p.description) like '%' || upper(m.original) || '%'
         limit 1), 
        'General'
    ) as subcategory_clean
from unioned_payments p