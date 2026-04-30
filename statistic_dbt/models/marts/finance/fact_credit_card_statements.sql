{{ config(materialized='table') }}

with raw_statements as (
    select * from {{ ref('stg_card_payments') }}
),

categories_mapping as (
    select * from {{ ref('keyword_mapping') }}
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
    left join categories_mapping c 
        on t.description ilike '%' || c.search_keyword || '%'
)

select
    payment_id,
    purchased_at,
    description,
    amount_brl,
    -- Prioritize SEED if the logic is generic
    case 
        when is_original_generic = true and matched_category is not null then matched_category
        else coalesce(original_category, 'Não Classificado')
    end as final_category,

    case 
        when is_original_generic = true and matched_sub_category is not null then matched_sub_category
        else 'Original do Cartão'
    end as final_sub_category,

    -- Null/False if there is no match
    coalesce(matched_is_essential, false) as is_essential
from refined