{{ config(
    materialized='table'
) }}

with fluxo_posicoes as (
    select
        initcap(m.investor) as investor,
        m.ticker,
        
        coalesce(sum(m.quantity), 0) as quantidade_cotas_atual,
        
        coalesce(sum(m.total_amount), 0) as saldo_financeiro_cdb
        
    from {{ ref('stg_stock_movements') }} m
    where m.investor in ('lucas', 'luísa', 'ricardo', 'casa')
      and m.ticker not in ('Dolar', 'Taxa Liquidação', 'Emolumentos', 'IRRS s/ operações')
    group by 1, 2
),

precos_mercado as (
    select 
        ticker,
        current_price
    from {{ ref('stg_current_prices') }}
)

select
    f.investor,
    f.ticker,
    
    case 
        when f.ticker = 'CDB' then 1 
        else round(f.quantidade_cotas_atual::numeric, 0)
    end as quantidade_total,
    
    case 
        when f.ticker = 'CDB' then round(f.saldo_financeiro_cdb::numeric, 2)
        else coalesce(p.current_price, 0.00)
    end as preco_atual,
    
    case 
        when f.ticker = 'CDB' then round(f.saldo_financeiro_cdb::numeric, 2)
        else round((f.quantidade_cotas_atual * coalesce(p.current_price, 0.00))::numeric, 2)
    end as montante_total
from fluxo_posicoes f
left join precos_mercado p on f.ticker = p.ticker
where 
    (f.ticker = 'CDB' and f.saldo_financeiro_cdb > 0) 
    or (f.ticker != 'CDB' and f.quantidade_cotas_atual > 0)
order by f.investor, montante_total desc