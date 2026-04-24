{{ config(materialized='table') }}

with movements as (
    select * from {{ ref('stg_stock_movements') }}
),

-- Consolidando a posição por ativo
investment_position as (
    select
        ticker,
        company_name,
        sum(case when transaction_type = 'compra' then quantity else -quantity end) as current_quantity,
        sum(case when transaction_type = 'compra' then total_amount else 0 end) as total_cost_basis,
        -- Preço Médio
        sum(case when transaction_type = 'compra' then total_amount else 0 end) / 
        nullif(sum(case when transaction_type = 'compra' then quantity else 0 end), 0) as average_buy_price
    from movements
    group by 1, 2
)

select 
    ticker,
    company_name,
    current_quantity,
    average_buy_price,
    total_cost_basis as total_invested_brl
from investment_position
where current_quantity > 0