with source as (
    -- Ajustado para o nome correto da tabela física no seu banco
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

mapped as (
    select
        c.*,
        m.tipo_gasto,
        m.grupo,
        m.categoria as category_name,
        m.subcategoria as subcategory_name
    from cleaned c
    left join {{ ref('category_mapping') }} m 
        on c.cleaned_description like concat('%', lower(m.search_term), '%')
)

select
    payment_id,
    amount_brl,
    purchased_at,
    payment_type,
    original_description as description,
    null as comments,
    
    coalesce(tipo_gasto, 'Variável') as tipo_gasto,
    coalesce(grupo, 'Outros') as grupo,
    coalesce(category_name, 'Não Classificado') as category_name,
    coalesce(subcategory_name, 'Não Classificado') as subcategory_name,
    
    is_internal_transfer,
    is_payment_transaction
from mapped