with source_data as (
    select * from {{ source('postgres_raw', 'payment_card') }}
)

select
    -- Creating an ID since there is no id on .csv file
    md5("Data de Compra" || "Descrição" || "Valor (em R$)" || arquivo_origem) as payment_id,
    "Valor (em R$)" as amount_brl,
    to_date("Data de Compra", 'DD/MM/YYYY') as purchased_at,
    lower("Descrição") as description,
    cast(null as varchar) as comments,
    upper("Categoria") as original_category,
    cast('credit_card' as varchar) as payment_type
from source_data