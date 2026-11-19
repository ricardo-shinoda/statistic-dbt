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
        
        -- 1. TIPO DE GASTO (Prioriza o Excel, usa fallback se vazio)
        coalesce(nullif(lower(trim(s.tipo_gasto)), ''), 'variável') as tipo_gasto,

        -- 2. CATEGORIA PRINCIPAL (Padroniza em minúsculo para bater com o cartão)
        case
            when lower(trim(s.category_name)) in ('alimentacao', 'alimentação') then 'alimentação'
            when nullif(trim(s.category_name), '') is not null then lower(trim(s.category_name))
            else 'Não Classificado'
        end as category_name,

        -- 3. SUBCATEGORIA 1 (Unifica Restaurante / Delivery / iFood em 'Comida Fora')
        case
            when lower(trim(s.subcategory_name1)) in (
                'restaurante', 'restaurantes', 'ifood', '99food', 'delivery', 'lanche', 'lanches', 'comida fora'
            ) then 'Comida Fora'
            when nullif(trim(s.subcategory_name1), '') is not null then trim(s.subcategory_name1)
            else 'Não Especificado'
        end as subcategory_name1,

        -- 4. SUBCATEGORIA 2 (Opcional: preserva o detalhe original se era iFood ou Restaurante)
        case
            when lower(trim(s.subcategory_name1)) in ('ifood', '99food', 'delivery') then 'Delivery'
            when lower(trim(s.subcategory_name1)) in ('restaurante', 'restaurantes', 'lanche', 'lanches') then 'Restaurante / Lanche'
            else coalesce(nullif(trim(s.subcategory_name2), ''), 'Não Especificado')
        end as subcategory_name2

    from cleaned c
    left join source_data s on c.payment_id = md5(cast(s.data_compra as varchar) || s.descricao || cast(s.valor as varchar) || s.arquivo_origem)
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