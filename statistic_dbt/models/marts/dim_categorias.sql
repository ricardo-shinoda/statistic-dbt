{{ config(materialized='table') }}

with staging as (
    select * from {{ ref('stg_pagamento_cartao') }}
)

select
    categoria_limpa as categoria,
    count(*) as total_transacoes,
    sum(valor_brl) as valor_total_acumulado
from staging
group by 1