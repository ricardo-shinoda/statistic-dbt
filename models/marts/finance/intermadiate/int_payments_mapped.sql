{{ config(materialized='ephemeral') }}

with raw_payments as (
    select 
        payment_id, amount_brl, purchased_at, payment_type, 
        description, comments, is_internal_transfer, is_payment_transaction
    from {{ ref('stg_pix_payments') }}

    union all

    select 
        payment_id, amount_brl, purchased_at, payment_type, 
        description, comments, is_internal_transfer, is_payment_transaction
    from {{ ref('stg_card_payments') }}
),

mapping as (
    select * from {{ ref('category_mapping') }}
),

ranked_matches as (
    select 
        p.*,
        m.tipo_gasto,
        m.grupo,
        m.categoria as category_name,
        m.subcategoria as subcategory_name,
        -- Pulo do gato: se houver mais de um match, ordena pelo tamanho do termo (mais específico primeiro)
        row_number() over (
            partition by p.payment_id 
            order by length(m.search_term) desc, m.search_term asc
        ) as rn
    from raw_payments p
    left join mapping m 
      on lower(p.description) like '%' || lower(m.search_term) || '%'
)

-- Filtra apenas o melhor match (rn = 1), eliminando qualquer linha duplicada
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
from ranked_matches
where rn = 1