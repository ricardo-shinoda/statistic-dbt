{{ config(
    materialized='table'
) }}

with base_movements as (
    select
        initcap(m.investor) as investor,
        m.ticker,
        m.quantity,
        m.total_amount,
        m.traded_at,
        row_number() over(
            partition by m.investor, m.ticker 
            order by m.traded_at desc
        ) as rn
    from {{ ref('stg_investments') }} m
    where trim(lower(m.investor)) in ('lucas', 'luísa', 'ricardo', 'casa')
      and trim(lower(m.ticker)) not in ('taxa liquidação', 'emolumentos', 'irrs s/ operações')
      and trim(lower(m.transaction_type)) not in ('dividendo', 'juros sobre capital', 'rendimento', 'rendimento (dividendo)', 'provento frações', 'calculo ir - venda', 'imposto a pagar')
),

fluxo_posicoes as (
    select
        investor,
        ticker,
        case 
            when ticker in ('CDB', 'CDI') then coalesce(max(case when rn = 1 then total_amount end), 0)
            else coalesce(sum(quantity), 0)
        end as volume_base
    from base_movements
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
        when f.ticker in ('CDB', 'CDI') then 1
        else round(f.volume_base::numeric, 0)
    end as quantidade_total,
    
    case 
        when f.ticker in ('CDB', 'CDI') then round(f.volume_base::numeric, 2)
        else coalesce(p.current_price, 0.00)
    end as preco_atual,
    
    case 
        when f.ticker in ('CDB', 'CDI') then round(f.volume_base::numeric, 2)
        else round((f.volume_base * coalesce(p.current_price, 0.00))::numeric, 2)
    end as montante_total
from fluxo_posicoes f
left join precos_mercado p on f.ticker = p.ticker
where f.volume_base > 0
order by f.investor, montante_total desc