with source_data as (
    select * from {{ source('postgres_raw', 'payment_pix') }}
)

select
    md5(cast(data_compra as varchar) || descricao || cast(valor as varchar) || arquivo_origem) as payment_id,
    cast(data_compra as date) as purchased_at,
    -- Convertendo timestamp para string antes de usar o lower
    lower(cast(dia_semana as varchar)) as week_day_raw,
    lower(descricao) as description,
    valor as amount_brl,
    lower(comentario) as comments,
    upper(categoria) as category_name,
    upper(subcategoria) as subcategory_name,
    cast('pix' as varchar) as payment_type
from {{ source('postgres_raw', 'payment_pix') }}