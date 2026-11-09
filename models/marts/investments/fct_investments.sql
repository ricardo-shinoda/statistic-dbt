with investments as (
    select * from {{ ref('stg_investments') }}
),

current_prices as (
    select * from {{ ref('stg_current_prices') }}
),

-- 1. Normaliza tickers e padroniza transações
cleaned_trades as (
    select
        investor,
        case 
            when upper(trim(ticker)) in ('DOLAR', 'DÓLAR', 'USD', 'USDBRL=X') then 'USDBRL=X'
            else upper(trim(ticker))
        end as ticker,
        lower(transaction_type) as transaction_type,
        coalesce(quantity, 0) as quantity,
        coalesce(total_amount, 0) as total_amount,
        coalesce(unit_price, 0) as unit_price
    from investments
    where ticker is not null
      and trim(ticker) <> ''
      and trim(ticker) <> '-'
      and lower(transaction_type) in (
          'compra', 'buy', 
          'venda', 'sell', 
          'aplicação', 'resgate', 
          'rendimento', 'saldo'
      )
      and upper(ticker) not in (
          'TAXA LIQUIDAÇÃO', 
          'IRRF S/ OPERAÇÕES', 
          'IRRS S/ OPERAÇÕES', 
          'EMOLUMENTOS', 
          'CORRETAGEM', 
          'ISS'
      )
),

-- 2. Agregação por ativo separando Compras, Vendas e Rendimentos
trade_aggregation as (
    select
        investor,
        ticker,
        sum(quantity) as net_quantity,
        -- Total financeiro aplicado em compras
        sum(case when lower(transaction_type) in ('compra', 'buy', 'aplicação') then total_amount else 0 end) as total_bought_brl,
        -- Total financeiro resgatado em vendas (convertido para valor positivo para subtração)
        sum(case when lower(transaction_type) in ('venda', 'sell', 'resgate') then abs(total_amount) else 0 end) as total_sold_brl,
        sum(case when lower(transaction_type) in ('compra', 'buy', 'aplicação') then quantity else 0 end) as total_bought_qty,
        -- Saldo Financeiro Atual Acumulado (Compras + Rendimentos - Vendas)
        sum(total_amount) as net_amount_brl
    from cleaned_trades
    group by investor, ticker
),

-- 3. Posições ativas e cálculo do Custo Histórico Remanescente
active_positions as (
    select 
        investor,
        ticker,
        net_quantity as quantity,
        greatest(net_amount_brl, 0) as net_amount_brl,
        case 
            -- Para Renda Fixa: Custo Histórico é a soma das aplicações MENOS os resgates efetuados
            when upper(ticker) like '%CDB%' 
              or upper(ticker) like '%RESERVA%' 
              or upper(ticker) like '%TESOURO%' 
              or upper(ticker) like '%LCI%' 
              or upper(ticker) like '%LCA%' then round(greatest(total_bought_brl - total_sold_brl, 0)::numeric, 2)
            
            -- Para Dólar, Ações e FIIs: Custo Histórico baseado na quantidade líquida x PM de compra
            else round((net_quantity * (case when total_bought_qty > 0 then total_bought_brl / total_bought_qty else 0 end))::numeric, 2)
        end as total_invested_brl
    from trade_aggregation
    where net_quantity > 0.01 
       or net_amount_brl > 0.01
)

-- 4. Cruzamento final com o preço atual de mercado (yfinance) e tratamento de Renda Fixa
select
    i.investor,
    case when i.ticker = 'USDBRL=X' then 'DÓLAR' else i.ticker end as ticker,
    i.quantity,
    i.total_invested_brl, -- Custo histórico real remanescente
    cp.current_price as market_price,
    case 
        -- Renda Fixa: Valor de mercado é o saldo total acumulado (Aplicações + Rendimentos - Resgates)
        when upper(i.ticker) like '%CDB%' 
          or upper(i.ticker) like '%RESERVA%' 
          or upper(i.ticker) like '%TESOURO%' 
          or upper(i.ticker) like '%LCI%' 
          or upper(i.ticker) like '%LCA%' then i.net_amount_brl

        -- Renda Variável e Dólar: Valor atualizado via yfinance
        when cp.current_price is not null and cp.current_price > 0 
            then round((i.quantity * cp.current_price)::numeric, 2)
            
        -- Fallback
        else i.total_invested_brl
    end as current_market_value_brl
from active_positions i
left join current_prices cp on i.ticker = cp.ticker