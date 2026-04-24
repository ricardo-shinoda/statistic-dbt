{{ config(materialized='view') }}

with source_data as (
    select * from {{ source('postgres_raw', 'nissan_kicks_consumption') }}
)

select
    -- Datas e Odômetro
    cast(data as date) as filled_at,
    odometro as odometer,
    
    -- Valores Financeiros
    total as total_amount,
    desconto as discount_amount,
    liters,
    preço_litro as price_per_liter,
    cashback_amount,
    
    -- Detalhes do Abastecimento
    lower(combustível) as fuel_type,
    lower(posto) as gas_station,
    kmv_pontos as kmv_points,
    
    -- Comparativos e Cálculos
    comparativo_combustivel as fuel_comparison,
    comparativo_preco as price_comparison,
    
    -- Dados do Computador de Bordo
    consumo_computador as trip_computer_consumption,
    velocidade_media_computador as average_speed,
    tempo_dirigido_computador as driving_time,
    total_km_computador as total_km_computer,
    km_restante_computador as remaining_range,
    
    -- Metadados
    arquivo_origem
from source_data