with investments as (
    select * from {{ ref('stg_investments') }}
),

current_prices as (
    select * from {{ ref('stg_current_prices') }}
)

select
    i.*,
    p.current_price as market_price,
    -- Se a coluna de total investido se chamar total_amount na sua base, calculamos ou usamos o campo correto:
    coalesce(i.quantity * i.unit_price, 0) as total_invested_brl,
    -- Cálculo do Valor Atual de Mercado (Mark-to-Market)
    coalesce(i.quantity * p.current_price, coalesce(i.quantity * i.unit_price, 0)) as current_market_value_brl
from investments i
left join current_prices p on i.ticker = p.ticker