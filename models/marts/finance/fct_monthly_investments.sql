{{ config(
    materialized='table'
) }}

with base_movements as (
    select
        initcap(m.investor) as investor,
        date_trunc('month', m.traded_at)::date as mes_competencia,
        m.total_amount,
        m.transaction_type,
        m.ticker
    from {{ ref('stg_stock_movements') }} m
    where trim(lower(m.investor)) in ('lucas', 'luísa', 'ricardo', 'casa')
    and trim(lower(m.ticker)) not in ('CDB')
)

select
    investor,
    mes_competencia,
    round(
        sum(
            case 
                when trim(lower(transaction_type)) in ('compra', 'aporte') then total_amount
                when trim(lower(transaction_type)) in ('venda', 'resgate') then -total_amount
                else 0 
            end
        )::numeric, 2
    ) as aporte_liquido
from base_movements
group by 1, 2
having sum(case when trim(lower(transaction_type)) in ('compra', 'aporte', 'venda', 'resgate') then total_amount else 0 end) > 0
order by mes_competencia desc, investor