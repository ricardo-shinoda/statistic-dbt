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
        end as is_internal_transfer,

        -- Campos de classificação vindos da planilha
        lower(trim(cast(s.tipo_gasto as varchar))) as tipo_gasto_raw,
        trim(cast(s.category_name as varchar)) as category_name_raw,
        trim(cast(s.subcategory_name1 as varchar)) as subcategory_name1_raw,
        trim(cast(s.subcategory_name2 as varchar)) as subcategory_name2_raw

    from source_data s
),

categorized as (
    select
        c.payment_id,
        c.purchased_at,
        c.amount_brl,
        c.payment_type,
        c.description,
        c.comments,
        c.is_internal_transfer,
        c.is_payment_transaction,

        -- 1. TIPO DE GASTO: mantém 'n/a' se estiver na planilha; só cai em 'variável' se vier vazio/nulo
        case
            when c.tipo_gasto_raw is null or c.tipo_gasto_raw = '' or c.tipo_gasto_raw in ('n/a', 'na') then 'n/a'
            else c.tipo_gasto_raw
        end as tipo_gasto,

        -- 2. CATEGORIA PRINCIPAL (Padroniza em minúsculo para bater com o cartão)
        case
            when lower(c.category_name_raw) in ('alimentacao', 'alimentação') then 'alimentação'
            when nullif(c.category_name_raw, '') is not null then lower(c.category_name_raw)
            else 'Não Classificado'
        end as category_name,

        -- 3. SUBCATEGORIA 1 (Unifica Restaurante / Delivery / iFood em 'Comida Fora')
        case
            when lower(c.subcategory_name1_raw) in (
                'restaurante', 'restaurantes', 'ifood', '99food', 'delivery', 'lanche', 'lanches', 'comida fora'
            ) then 'Comida Fora'
            when nullif(c.subcategory_name1_raw, '') is not null then c.subcategory_name1_raw
            else 'Não Especificado'
        end as subcategory_name1,

        -- 4. SUBCATEGORIA 2 (Opcional: preserva o detalhe original se era iFood ou Restaurante)
        case
            when lower(c.subcategory_name1_raw) in ('ifood', '99food', 'delivery') then 'Delivery'
            when lower(c.subcategory_name1_raw) in ('restaurante', 'restaurantes', 'lanche', 'lanches') then 'Restaurante / Lanche'
            else coalesce(nullif(c.subcategory_name2_raw, ''), 'Não Especificado')
        end as subcategory_name2

    from cleaned c
)

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
from categorized