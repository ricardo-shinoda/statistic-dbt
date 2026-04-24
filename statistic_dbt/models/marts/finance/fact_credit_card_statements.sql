-- {{ config(materialized='table') }}

-- with raw_statements as (
--     select * from {{ ref('stg_card_payments') }}
-- ),

-- categories_seed as (
--     select * from {{ ref('seed_category_mapping') }}
-- ),

-- refined as (
--     select 
--         t.*,
--         c.description as seed_category,
--         c.sub_category as seed_sub_category,
--         c.is_essential as seed_is_essential,
--         -- Aqui definimos o que é considerado "lixo" ou genérico na origem
--         case 
--             when t.original_category in ('Outros', 'Serviços', 'Diversos', '', null) then true
--             else false
--         end as is_original_generic
--     from raw_statements t
--     left join categories_seed c 
--         on t.description ilike '%' || c.search_keyword || '%'
-- )

-- select
--     transaction_id,
--     transaction_date,
--     description,
--     amount,
--     -- LÓGICA INTELIGENTE:
--     -- Se a original for genérica E achamos algo no seed, usa o seed.
--     -- Se a original NÃO for genérica, mantém a original.
--     case 
--         when is_original_generic = true and seed_category is not null then seed_category
--         else coalesce(original_category, 'Não Classificado')
--     end as final_category,

--     case 
--         when is_original_generic = true and seed_sub_category is not null then seed_sub_category
--         else 'Original do Cartão'
--     end as final_sub_category,

--     coalesce(seed_is_essential, false) as is_essential
-- from refined


{{ config(materialized='table') }}

with raw_statements as (
    select * from {{ ref('stg_card_payments') }}
),

-- 1. Verifique se este nome aqui...
categories_mapping as (
    select * from {{ ref('seed_category_mapping') }}
),

refined as (
    select 
        t.*,
        c.category as matched_category,
        c.sub_category as matched_sub_category,
        c.is_essential as matched_is_essential,
        case 
            when t.original_category in ('Outros', 'Serviços', 'Diversos', '', null) then true
            else false
        end as is_original_generic
    from raw_statements t
    -- 2. ...é exatamente o mesmo que este aqui!
    left join categories_mapping c 
        on t.description ilike '%' || c.search_keyword || '%'
)

select
    payment_id,
    purchased_at,
    description,
    amount_brl,
    -- Lógica para priorizar o Seed se a origem for genérica
    case 
        when is_original_generic = true and matched_category is not null then matched_category
        else coalesce(original_category, 'Não Classificado')
    end as final_category,

    case 
        when is_original_generic = true and matched_sub_category is not null then matched_sub_category
        else 'Original do Cartão'
    end as final_sub_category,

    -- Se não houver match, assume falso (ou nulo)
    coalesce(matched_is_essential, false) as is_essential
from refined