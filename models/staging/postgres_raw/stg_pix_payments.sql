{{ config(materialized='view') }}

with source_data as (
    select * from {{ source('postgres_raw', 'payment_pix') }}
),

cleaned as (
    select
        md5(cast(s.data_compra as varchar) || s.descricao || cast(s.valor as varchar) || s.arquivo_origem) as payment_id,
        cast(s.data_compra as date) as purchased_at,
        lower(cast(s.dia_semana as varchar)) as week_day_raw,
        
        s.descricao as original_description,
        lower(s.descricao) as description,
        s.valor as amount_brl,
        lower(s.comentario) as comments,
        
        cast('pix' as varchar) as payment_type,
        true as is_payment_transaction,
        
        case 
            when lower(s.descricao) ilike '%fatura%' then true
            when lower(s.descricao) ilike '%c6 bank%' then true
            else false
        end as is_internal_transfer

    from source_data s
),

categorized as (
    select
        c.*,
        
        -- 1. TIPO DE GASTO (Essencial ou Variável)
        case 
            when description ilike '%pix de alguém importante%' -- substitua por regras se necessário
              or description ilike '%aluguel%' 
              or description ilike '%condominio%' 
              or description ilike '%energia%' 
              or description ilike '%agua%' then 'essencial'
            else 'variável'
        end as tipo_gasto,

        -- 2. CATEGORIA PRINCIPAL (category_name)
        case
            when description ilike '%pix de alguém importante%' then 'Transferências'
            when description ilike '%mercado%' or description ilike '%confianca%' then 'Alimentação'
            else 'Não Classificado'
        end as category_name,

        -- 3. SUBCATEGORIA 1 (subcategory_name1)
        case
            when description ilike '%mercado%' then 'Mercado'
            else 'Não Especificado'
        end as subcategory_name1,

        -- 4. SUBCATEGORIA 2 (subcategory_name2)
        'Não Especificado' as subcategory_name2

    from cleaned c
)

select
    payment_id,
    purchased_at,
    amount_brl,
    payment_type,
    description,
    comments,
    
    coalesce(tipo_gasto, 'variável') as tipo_gasto,
    coalesce(category_name, 'Não Classificado') as category_name,
    coalesce(subcategory_name1, 'Não Especificado') as subcategory_name1,
    coalesce(subcategory_name2, 'Não Especificado') as subcategory_name2,
    
    is_internal_transfer,
    is_payment_transaction
from categorized