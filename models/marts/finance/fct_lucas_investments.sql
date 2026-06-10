{{ config(
    materialized='table'
) }}

with dados_consolidados as (
    -- 1. Calcula tanto as cotas quanto o valor financeiro investido direto da RAW
    select
        investor,
        ticker,
        -- Regra para cotas ordinárias (Ações/FIIs)
        coalesce(sum(
            case 
                when transaction_type = 'Compra' then quantity
                when transaction_type = 'Venda' then -quantity
                else 0 
            end
        ), 0) as quantidade_cotas,
        -- Regra para o valor financeiro acumulado (usando o CDB) com a coluna correta
        coalesce(sum(
            case 
                when transaction_type = 'Compra' then total_amount
                when transaction_type = 'Venda' then -total_amount
                else 0 
            end
        ), 0) as valor_investido_financeiro
    from postgres_raw.stock_movements
    where lower(investor) = 'lucas'
    group by 1, 2
),

precos_mercado as (
    -- 2. Busca os preços que o seu script Python atualizou no banco
    select 
        ticker,
        current_price
    from postgres_raw.current_prices
)

-- 3. Monta o resultado final aplicando a exceção para o CDB
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