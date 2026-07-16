{{ config(
    materialized='table'
) }}

with recursive indexed_transactions as (
    select
        row_number() over (partition by ticker, investor order by traded_at asc) as transaction_index,
        traded_at::date as traded_date,
        ticker,
        investor,
        transaction_type,
        case 
            when lower(transaction_type) = 'venda' and quantity > 0 then quantity * -1
            else quantity
        end as quantity,
        unit_price
    from {{ ref('stg_investments') }}
    where ticker != 'CDB_Caixa_102.0'
),

trade_history_recursive as (
    select
        transaction_index,
        traded_date,
        ticker,
        investor,
        transaction_type,
        quantity as qtd_acumulada,
        unit_price as preco_medio,
        (quantity * unit_price) as custo_aplicado
    from indexed_transactions
    where transaction_index = 1

    union all

    select
        t.transaction_index,
        t.traded_date,
        t.ticker,
        t.investor,
        t.transaction_type,
        case 
            when lower(t.transaction_type) = 'saldo' then t.quantity
            else (r.qtd_acumulada + t.quantity)
        end as qtd_acumulada,
        case
            when lower(t.transaction_type) = 'saldo' then t.unit_price
            when (r.qtd_acumulada + t.quantity) <= 0 then 0
            when t.quantity > 0 then 
                ((r.qtd_acumulada * r.preco_medio) + (t.quantity * t.unit_price)) / (r.qtd_acumulada + t.quantity)
            else r.preco_medio
        end as preco_medio,
        case
            when lower(t.transaction_type) = 'saldo' then (t.quantity * t.unit_price)
            when (r.qtd_acumulada + t.quantity) <= 0 then 0
            else (r.qtd_acumulada + t.quantity) * case
                when t.quantity > 0 then 
                    ((r.qtd_acumulada * r.preco_medio) + (t.quantity * t.unit_price)) / (r.qtd_acumulada + t.quantity)
                else r.preco_medio
            end
        end as custo_aplicado
    from indexed_transactions t
    join trade_history_recursive r 
        on t.ticker = r.ticker 
        and t.investor = r.investor
        and t.transaction_index = r.transaction_index + 1
),

monthly_snapshots as (
    -- 3. Pega o último saldo válido de cada investidor no mês
    select distinct on (date_trunc('month', traded_date)::date, ticker, investor)
        date_trunc('month', traded_date)::date as data_mes,
        ticker,
        investor,
        qtd_acumulada,
        custo_aplicado as custo_no_mes
    from trade_history_recursive
    order by date_trunc('month', traded_date)::date, ticker, investor, traded_date desc, transaction_index desc
),

-- 4. Matriz de tempo dinâmica baseada nos dados reais que passaram pelo filtro
all_months as (
    select distinct date_trunc('month', traded_at)::date as data_mes from {{ ref('stg_investments') }}
),
all_tickers as (
    select distinct ticker from {{ ref('stg_investments') }} where ticker != 'CDB_Caixa_102.0'
),
all_investors as (
    select distinct investor from {{ ref('stg_investments') }}
),
timeline_matrix as (
    select m.data_mes, t.ticker, i.investor 
    from all_months m 
    cross join all_tickers t
    cross join all_investors i
),

filled_portfolio as (
    select
        matrix.data_mes,
        matrix.ticker,
        matrix.investor,
        coalesce(snap.qtd_acumulada, 
            lag(snap.qtd_acumulada) over (partition by matrix.ticker, matrix.investor order by matrix.data_mes)
        ) as qtd_no_mes,
        coalesce(snap.custo_no_mes, 
            lag(snap.custo_no_mes) over (partition by matrix.ticker, matrix.investor order by matrix.data_mes)
        ) as custo_no_mes
    from timeline_matrix matrix
    left join monthly_snapshots snap 
        on matrix.data_mes = snap.data_mes 
        and matrix.ticker = snap.ticker 
        and matrix.investor = snap.investor
),

latest_market_prices as (
    select ticker, current_price from {{ ref('stg_current_prices') }}
),

metrics_per_month as (
    select
        f.data_mes,
        f.investor,
        f.ticker,
        coalesce(f.custo_no_mes, 0) as valor_aplicado,
        case 
            when coalesce(f.qtd_no_mes, 0) <= 0 then 0
            when p.current_price is not null then (f.qtd_no_mes * p.current_price)
            else coalesce(f.custo_no_mes, 0)
        end as valor_mercado
    from filled_portfolio f
    left join latest_market_prices p on f.ticker = p.ticker
    where f.qtd_no_mes > 0 or f.custo_no_mes > 0
)

select
    data_mes,
    investor,
    ticker,
    sum(valor_aplicado) as total_aplicado,
    sum(valor_mercado) as total_atual,
    sum(valor_mercado) - sum(valor_aplicado) as ganho_de_capital
from metrics_per_month
group by 1, 2, 3
order by data_mes asc, investor asc, ticker asc