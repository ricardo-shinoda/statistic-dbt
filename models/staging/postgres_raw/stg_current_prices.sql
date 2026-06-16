{{ config(materialized='view') }}

with source_data as (
    select * from {{ source('postgres_raw', 'current_prices') }}
)

select
    upper(ticker) as ticker,
    cast(current_price as numeric) as current_price
from source_data