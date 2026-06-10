{{ config(
    materialized='table'
) }}

with historico_proventos as (
    -- 1. Filtra apenas os registros que representam entrada de proventos/dividendos
    select
        initcap(lower(m.investor)) as investor,
        m.ticker,
        -- Mantém a classificação original (Dividendo, JCE, Rendimento, etc.) para análise detalhada
        initcap(lower(m.transaction_type)) as tipo_provento,
        m.transaction_date,
        -- Extrai o mês/ano do evento para facilitar análises sazonais e mensais
        date_trunc('month', m.transaction_date)::date as mes_competencia,
        m.total_amount as valor_recebido
    from postgres_raw.stock_movements m
    where lower(m.investor) in ('lucas', 'luísa', 'ricardo', 'casa')
      and (
          lower(m.transaction_type) like '%rendimento%'
          or lower(m.transaction_type) like '%dividendo%'
          or lower(m.transaction_type) like '%juros sobre capital%'
          or lower(m.transaction_type) like '%provento%'
      )
)

-- 2. Entrega o histórico limpo e ordenado pelos recebimentos mais recentes
select
    investor,
    ticker,
    tipo_provento,
    transaction_date,
    mes_competencia,
    round(valor_recebido::numeric, 2) as valor_recebido
from historico_proventos
order by transaction_date desc, investor