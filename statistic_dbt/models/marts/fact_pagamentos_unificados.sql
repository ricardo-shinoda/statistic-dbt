{{ config(materialized='table') }}

with cartao as (
    select * from {{ ref('stg_pagamento_cartao') }}
),

pix as (
    select * from {{ ref('stg_pagamento_pix') }}
),

unificado as (
    select * from cartao
    union all
    select * from pix
)

select * from unificado