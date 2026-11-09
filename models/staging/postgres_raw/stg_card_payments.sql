{{ config(materialized='view') }}

with source as (
    select * from {{ source('postgres_raw', 'payment_card') }}
),

cleaned as (
    select
        md5(concat(
            coalesce("Data de Compra"::text, ''), 
            coalesce("Descrição", ''), 
            coalesce("Valor (em R$)"::text, '0')
        )) as payment_id,
        
        to_date("Data de Compra", 'DD/MM/YYYY') as purchased_at,
        "Valor (em R$)"::numeric as amount_brl,
        
        "Descrição" as original_description,
        
        trim(regexp_replace(
            lower("Descrição"), 
            '^(pag\*|mp\*|ifd\*|itau\*|uber\*|pax\*|rec\*|ame\*|compra\s+).\*?\s*', 
            ''
        )) as cleaned_description,
        
        'credit_card' as payment_type,
        false as is_internal_transfer,
        true as is_payment_transaction
    from source
),

categorized as (
    select
        c.*,
        
        -- 1. TIPO DE GASTO (Essencial ou Variável)
        case 
            when cleaned_description ilike '%drogasil%' 
              or cleaned_description ilike '%drogal%' 
              or cleaned_description ilike '%farmacia%' 
              or cleaned_description ilike '%posto%' 
              or cleaned_description ilike '%ipiranga%' 
              or cleaned_description ilike '%shell%' 
              or cleaned_description ilike '%confianca%' 
              or cleaned_description ilike '%sams%' 
              or cleaned_description ilike '%carrefour%' then 'essencial'
            else 'variável'
        end as tipo_gasto,

        -- 2. CATEGORIA PRINCIPAL (category_name)
        case
            when cleaned_description ilike '%ifd%' 
              or cleaned_description ilike '%ifood%' 
              or original_description ilike '%ifd%'
              or original_description ilike '%ifood%' 
              or cleaned_description ilike '%restaurante%' 
              or cleaned_description ilike '%bobs%' 
              or cleaned_description ilike '%burger%' 
              or cleaned_description ilike '%padaria%'
              or cleaned_description ilike '%mercado%'
              or cleaned_description ilike '%confianca%' 
              or cleaned_description ilike '%sams%' 
              or cleaned_description ilike '%tauste%'
              or cleaned_description ilike '%carrefour%' then 'alimentação'
              
            when cleaned_description ilike '%uber%' 
              or cleaned_description ilike '%99app%' 
              or cleaned_description ilike '%posto%' 
              or cleaned_description ilike '%ipiranga%' 
              or cleaned_description ilike '%shell%' then 'transporte'
              
            when cleaned_description ilike '%drogasil%' 
              or cleaned_description ilike '%drogal%' 
              or cleaned_description ilike '%farmacia%' 
              or cleaned_description ilike '%unimed%' then 'saúde'
              
            when cleaned_description ilike '%amazon%' 
              or cleaned_description ilike '%netflix%' 
              or cleaned_description ilike '%spotify%' 
              or cleaned_description ilike '%prime%' then 'lazer / bem estar'
              
            else 'Não Classificado'
        end as category_name,

        -- 3. SUBCATEGORIA 1 (subcategory_name1) - CORRIGIDO (Removido o duplo case)
        case
            when cleaned_description ilike '%ifd%' 
              or cleaned_description ilike '%ifood%' 
              or original_description ilike '%ifd%'
              or original_description ilike '%ifood%' then 'iFood'
            when cleaned_description ilike '%confianca%' 
              or cleaned_description ilike '%sams%' 
              or cleaned_description ilike '%tauste%' 
              or cleaned_description ilike '%carrefour%' then 'Mercado'
            when cleaned_description ilike '%uber%' 
              or cleaned_description ilike '%99app%' then 'Motorista de App'
            when cleaned_description ilike '%posto%' 
              or cleaned_description ilike '%ipiranga%' 
              or cleaned_description ilike '%shell%' then 'Combustível'
            when cleaned_description ilike '%drogasil%' 
              or cleaned_description ilike '%drogal%' 
              or cleaned_description ilike '%farmacia%' then 'Medicamento'
            else 'Não Especificado'
        end as subcategory_name1,

        -- 4. SUBCATEGORIA 2 (subcategory_name2)
        'Não Especificado' as subcategory_name2

    from cleaned c
)

select
    payment_id,
    amount_brl,
    purchased_at,
    payment_type,
    original_description as description,
    null as comments,
    
    coalesce(tipo_gasto, 'variável') as tipo_gasto,
    coalesce(category_name, 'Não Classificado') as category_name,
    coalesce(subcategory_name1, 'Não Especificado') as subcategory_name1,
    coalesce(subcategory_name2, 'Não Especificado') as subcategory_name2,
    
    is_internal_transfer,
    is_payment_transaction
from categorized