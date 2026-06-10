with source_data as (
    select * from {{ source('postgres_raw', 'payment_card') }}
)

select
    md5("Data de Compra" || "Descrição" || "Valor (em R$)" || arquivo_origem) as payment_id,
    "Valor (em R$)" as amount_brl,
    to_date("Data de Compra", 'DD/MM/YYYY') as purchased_at,
    lower("Descrição") as description,
    cast(null as varchar) as comments,
    upper("Categoria") as original_category,
    cast('credit_card' as varchar) as payment_type,
    arquivo_origem as invoice_name,
    case 
        when lower("Descrição") ilike '%inclusao de pagamento%' then true
        when lower("Descrição") ilike '%pagamento efetuado%' then true
        when lower("Descrição") ilike '%pagamento recebido%' then true
        else false
    end as is_payment_transaction
from source_data