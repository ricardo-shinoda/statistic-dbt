{{ config(materialized='view') }}

with source_data as (
    select * from {{ source('postgres_raw', 'stock_movements') }}
)

select
    md5(cast(transaction_date as varchar) || ticker || transaction_type || cast(quantity as varchar)) as stock_movement_id,
    
    lower(investor) as investor,
    lower(transaction_type) as transaction_type,
    cast(transaction_date as date) as traded_at,
    upper(ticker) as ticker,
    lower(organization) as company_name,
    cnpj,
    
    -- Garante que a quantidade de cotas fique negativa na venda para subtrair do estoque
    case 
        when lower(transaction_type) = 'venda' then -1 * abs(quantity)
        else abs(quantity)
    end as quantity,
    
    unit_price,
    
    -- Como você disse que o total_amount já vem subtraindo na origem, 
    -- apenas garantimos que ele mantenha o sinal correto aqui
    total_amount, 
    
    "Taxa de liquidação" as settlement_fee,
    "Emolumentos" as emoluments,
    "IRFR s/ operações" as income_tax_withheld,
    "month" as report_month,
    "To invest" as target_invest_amount,
    "Difference" as price_difference,
    
    arquivo_origem
from source_data