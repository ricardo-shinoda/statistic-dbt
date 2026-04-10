with source_data as (
    -- Aqui usamos a função ref/source para criar a dependência
    select * from {{ source('postgres_raw', 'pagamento_cartao') }}
)

select
    cast(id as varchar) as pagamento_id,
    valor_brl,
    data_compra,
    descricao,
    cast(null as varchar) as comentario,        -- Criando coluna vazia
    cast(null as varchar) as metodo_pagamento, -- Criando coluna vazia
    upper(categoria) as categoria_limpa,
    cast('cartão' as varchar) as tipo_pagamento
from source_data