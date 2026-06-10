{{ config(materialized='view') }}

with source_data as (
    select * from {{ source('postgres_raw', 'stock_movements') }}
)

select
    -- Unique identifier (Hash Key)
    md5(cast(transaction_date as varchar) || ticker || transaction_type || cast(quantity as varchar)) as stock_movement_id,
    
    -- Transactions atribute
    lower(investor) as investor,
    lower(transaction_type) as transaction_type,
    cast(transaction_date as date) as traded_at,
    upper(ticker) as ticker,
    lower(organization) as company_name,
    cnpj,
    
    -- Values and quantities
    quantity,
    unit_price,
    total_amount,
    
    -- Tax and costs
    "Taxa de liquidação" as settlement_fee,
    "Emolumentos" as emoluments,
    "IRFR s/ operações" as income_tax_withheld,
    
    -- control collumn and auxiliary from excel
    "month" as report_month,
    "To invest" as target_invest_amount,
    "Difference" as price_difference,
    
    -- Metadada
    arquivo_origem
from source_data