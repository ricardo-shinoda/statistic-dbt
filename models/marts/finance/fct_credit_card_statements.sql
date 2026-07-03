{{ config(materialized='table') }}

with raw_statements as (
    select * from {{ ref('stg_card_payments') }}
    -- Filtrando apenas o que faz sentido para o report de statements, se necessário
    -- (Nota: na stg_card_payments setamos is_payment_transaction = true por padrão, 
    -- mude aqui para true ou remova o filtro se quiser ver todos os gastos mapeados)
    where is_payment_transaction = true
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
        -- Se veio como 'Não Classificado' do seed principal, consideramos genérico para tentar remapear via keyword
        case 
            when t.category_name = 'Não Classificado' then true
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
    payment_type,
    
    -- Hierarquia inteligente de fallback
    tipo_gasto,
    grupo,
    
    case 
        when is_original_generic = true and matched_category is not null then matched_category
        else category_name
    end as final_category,

    case 
        when is_original_generic = true and matched_sub_category is not null then matched_sub_category
        else subcategory_name
    end as final_sub_category,

    case 
        when tipo_gasto = 'Essencial' then true
        when tipo_gasto = 'Variável' then false
        else coalesce(matched_is_essential, false)
    end as is_essential
from refined