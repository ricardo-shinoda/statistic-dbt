{{ config(materialized='view') }}

with source_data as (
    select * from {{ source('postgres_raw', 'nissan_kicks_consumption') }}
)

select
    -- Datas and odometer
    cast(data as date) as filled_at,
    odometro as odometer,
    
    -- Finance values
    total as total_amount,
    desconto as discount_amount,
    liters,
    preço_litro as price_per_liter,
    litro_descontado as actual_price_per_liter,
    cashback_amount,
    
    -- Gas filling
    lower(combustível) as fuel_type,
    lower(posto) as gas_station,
    kmv_pontos as kmv_points,
    
    -- Calculation and comparison
    comparativo_combustivel as fuel_comparison,
    comparativo_preco as price_comparison,
    
    -- Data from vehicle computer
    consumo_computador as trip_computer_consumption,
    velocidade_media_computador as average_speed,
    tempo_dirigido_computador as driving_time,
    total_km_computador as total_km_computer,
    km_restante_computador as remaining_range,
    
    -- Metadata
    arquivo_origem
from source_data