{{ config(materialized='table') }}

-- A Fact agora é apenas a visão final, limpa e performática
select
    payment_id,
    amount_brl,
    purchased_at,
    description,
    comments,
    payment_type,
    category_clean as category_name,     -- Aqui você usa a categoria já limpa
    subcategory_clean as subcategory_name -- Aqui você usa a subcategoria limpa
from {{ ref('payments') }}