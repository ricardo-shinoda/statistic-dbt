{{ config(materialized='table') }}

with movements as (
    select * from {{ ref('stg_investments') }}
),

investment_position as (
    select
        investor,
        ticker,
        max(company_name) as company_name,
        
        -- Soma da quantidade líquida
        sum(case when transaction_type = 'compra' then quantity else -quantity end) as current_quantity,
        
        -- Se total_amount na planilha já vem com o sinal (- ou +):
        sum(total_amount) as total_invested_brl
        
    from movements
    group by investor, ticker
)

select 
    investor,
    ticker,
    company_name,
    current_quantity,
    total_invested_brl,
    -- Preço médio calculado após consolidar o ativo
    total_invested_brl / nullif(current_quantity, 0) as average_buy_price
from investment_position
where current_quantity > 0