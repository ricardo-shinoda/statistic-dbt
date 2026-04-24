{{ config(materialized='table') }}

with staging as (
    select * from {{ ref('stg_vehicle_consumption') }}
),

final as (
    select
        filled_at,
        odometer,
        -- Cálculo de KM rodados entre abastecimentos (usando window function)
        odometer - lag(odometer) over (order by filled_at) as km_driven,
        
        fuel_type,
        gas_station,
        liters,
        total_amount,
        price_per_liter,
        
        -- Eficiência real (KM/L)
        case 
            when liters > 0 then (odometer - lag(odometer) over (order by filled_at)) / liters 
            else null 
        end as km_per_liter,
        
        -- Custo por KM
        case 
            when (odometer - lag(odometer) over (order by filled_at)) > 0 
            then total_amount / (odometer - lag(odometer) over (order by filled_at))
            else null 
        end as cost_per_km,

        trip_computer_consumption as onboard_computer_km_l,
        arquivo_origem
    from staging
)

select * from final