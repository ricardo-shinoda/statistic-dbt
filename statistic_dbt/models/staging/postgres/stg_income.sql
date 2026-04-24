with source as (
    select * from {{ source('postgres_raw', 'income') }}
),

renamed as (
    select
        cast("income_date" as date) as income_date,
        lower(description) as description,
        lower(receiver) as receiver,
        lower(company) as company_paying,
        cast("value" as decimal(10,2)) as amount,
        dolar as dollar_cotation,
        lower(intermediate_bank) as intermediate_bank,
        arquivo_origem
    from source
    where "income_date" is not NULL
        and "value" > 0

)

select * from renamed