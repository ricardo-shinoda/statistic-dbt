{{ config(materialized='table') }}

select
    payment_id,
    amount_brl,
    purchased_at,
    payment_type,
    description,
    comments,
    
    coalesce(tipo_gasto, 'Variável') as tipo_gasto,
    coalesce(grupo, 'Outros') as grupo,
    coalesce(category_name, 'Não Classificado') as category_name,
    coalesce(subcategory_name, 'Não Classificado') as subcategory_name,
    
    is_internal_transfer,
    is_payment_transaction
from {{ ref('int_payments_mapped') }}
where not is_internal_transfer