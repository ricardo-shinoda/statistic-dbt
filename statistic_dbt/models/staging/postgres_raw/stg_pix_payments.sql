with source_data as (
    select * from {{ source('postgres_raw', 'payment_pix') }}
)

select
    md5(cast(data_compra as varchar) || descricao || cast(valor as varchar) || arquivo_origem) as payment_id,
    cast(data_compra as date) as purchased_at,
    lower(cast(dia_semana as varchar)) as week_day_raw,
    
    -- AQUI ESTÁ O AJUSTE:
    lower(descricao) as description, -- O banco tem 'descricao', o dbt quer 'description'
    
    valor as amount_brl,
    lower(comentario) as comments,
    upper(categoria) as original_category,
    upper(subcategoria) as subcategory_name,
    cast('pix' as varchar) as payment_type,
    
    case 
        when lower(descricao) ilike '%fatura%' then true
        when lower(descricao) ilike '%c6 bank%' then true
        when upper(categoria) = 'PAGAMENTOS' and upper(subcategoria) = 'CARTÃO DE CRÉDITO' then true
        else false
    end as is_internal_transfer

from source_data