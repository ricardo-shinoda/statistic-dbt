{{ config(
    materialized='table'
) }}

with dados_consolidados as (
    select
        investor,
        ticker,
        coalesce(sum(
            case 
                when transaction_type = 'Compra' then quantity
                when transaction_type = 'Venda' then -quantity
                else 0 
            end
        ), 0) as quantidade_cotas,
        coalesce(sum(
            case 
                when transaction_type = 'Compra' then total_amount
                when transaction_type = 'Venda' then -total_amount
                else 0 
            end
        ), 0) as valor_investido_financeiro
    from {{ ref('stg_stock_movements')}}
    where lower(investor) = 'lucas'
    group by 1, 2
),

precos_mercado as (
    select 
        ticker,
        current_price
    from {{ ref('stg_current_prices')}}
)

select
    d.investor,
    d.ticker,
    case 
        when d.ticker = 'CDB' then 1 -- Para CDB, fixamos a cota em 1 unidade de carteira
        else d.quantidade_cotas 
    end as quantidade_cotas,
    case 
        when d.ticker = 'CDB' then round(d.valor_investido_financeiro::numeric, 2)
        else coalesce(p.current_price, 0.00) 
    end as preco_atual_mercado,
    case 
        when d.ticker = 'CDB' then round(d.valor_investido_financeiro::numeric, 2)
        else round((d.quantidade_cotas * coalesce(p.current_price, 0.00))::numeric, 2)
    end as patrimonio_atual_total
from dados_consolidados d
left join precos_mercado p on d.ticker = p.ticker
where 
    (d.ticker = 'CDB' and d.valor_investido_financeiro > 0) 
    or (d.ticker != 'CDB' and d.quantidade_cotas > 0)
order by patrimonio_atual_total desc