{{ config(
    materialized='table'
) }}

with fluxo_posicoes as (
    -- 1. Calcula as quantidades e saldos reais tirando os ruídos do histórico
    select
        initcap(lower(m.investor)) as investor,
        m.ticker,
        
        -- Quantidade líquida de cotas (para ações e FIIs)
        coalesce(sum(
            case 
                when m.transaction_type = 'Compra' then m.quantity
                when m.transaction_type = 'Venda' then -m.quantity
                else 0 
            end
        ), 0) as quantidade_cotas_atual,
        
        -- Saldo financeiro líquido (para o CDB)
        coalesce(sum(
            case 
                when m.transaction_type = 'Compra' then m.total_amount
                when m.transaction_type = 'Venda' then -m.total_amount
                else 0 
            end
        ), 0) as saldo_financeiro_cdb
    from postgres_raw.stock_movements m
    where lower(m.investor) in ('lucas', 'luísa', 'ricardo', 'casa')
      and m.ticker not in ('Dolar', 'Taxa Liquidação', 'Emolumentos', 'IRRS s/ operações')
    group by 1, 2
),

precos_mercado as (
    -- 2. Busca o preço atual dos ativos
    select 
        ticker,
        current_price
    from postgres_raw.current_prices
)

-- 3. Gera o output limpo com quantidade e montante lado a lado
select
    f.investor,
    f.ticker,
    
    -- Quantidade: Para ações traz as cotas, para CDB fixamos 1 (ou o saldo se preferir)
    case 
        when f.ticker = 'CDB' then 1 
        else round(f.quantidade_cotas_atual::numeric, 0)
    end as quantidade_total,
    
    -- Preço unitário de mercado atual
    case 
        when f.ticker = 'CDB' then round(f.saldo_financeiro_cdb::numeric, 2)
        else coalesce(p.current_price, 0.00)
    end as preco_atual,
    
    -- Montante Total (Patrimônio)
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