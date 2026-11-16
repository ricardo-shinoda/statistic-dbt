{{ config(
    materialized='table'
) }}

with provents_history as (
    select
        initcap(lower(m.investor)) as investor,
        m.ticker,
        initcap(lower(m.transaction_type)) as tipo_provento,
        m.traded_at,
        date_trunc('month', m.traded_at)::date as mes_competencia,
        m.total_amount as valor_recebido
    from {{ ref('stg_investments')}} m
    where lower(m.investor) in ('lucas', 'luísa', 'ricardo', 'casa')
      and (
          lower(m.transaction_type) like '%rendimento%'
          or lower(m.transaction_type) like '%dividendo%'
          or lower(m.transaction_type) like '%juros sobre capital%'
          or lower(m.transaction_type) like '%provento%'
      )
      -- Exclui apenas títulos de Renda Fixa, mantendo Ações, FIIs e Fiagros (ex: SNAG11)
      and upper(m.ticker) not like '%CDB%'
      and upper(m.ticker) not like '%LCI%'
      and upper(m.ticker) not like '%LCA%'
      and upper(m.ticker) not like '%TESOURO%'
      and upper(m.ticker) not like '%RESERVA%'
)

select
    investor,
    ticker,
    tipo_provento,
    traded_at,
    mes_competencia,
    round(valor_recebido::numeric, 2) as valor_recebido
from provents_history
order by traded_at desc, investor