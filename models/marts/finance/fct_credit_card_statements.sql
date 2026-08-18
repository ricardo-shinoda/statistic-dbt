{{ config(materialized='table') }}

with raw_statements as (
    select 
        payment_id,
        purchased_at,
        description,
        amount_brl,
        payment_type,
        is_payment_transaction
    from {{ ref('stg_card_payments') }}
    where is_payment_transaction = true
),

categories_mapping as (
    select * from {{ ref('category_mapping') }}
),

refined as (
    select 
        s.payment_id,
        s.purchased_at,
        s.description,
        s.amount_brl,
        s.payment_type,
        
        m.tipo_gasto,
        m.grupo,
        m.categoria as matched_category,
        m.subcategoria as matched_sub_category
    from raw_statements s
    left join categories_mapping m 
        on lower(s.description) like '%' || lower(m.search_term) || '%'
)

select
    payment_id,
    purchased_at,
    description,
    amount_brl,
    payment_type,
    
    coalesce(tipo_gasto, 'Variável') as tipo_gasto,
    coalesce(grupo, 'Outros') as grupo,
    coalesce(matched_category, 'Não Classificado') as final_category,
    coalesce(matched_sub_category, 'Não Classificado') as final_sub_category,

    case 
        when tipo_gasto = 'Essencial' then true
        else false
    end as is_essential
from refined