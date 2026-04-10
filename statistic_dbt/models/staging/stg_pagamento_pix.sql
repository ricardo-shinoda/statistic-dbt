with source_data as (
    select * from {{ source('postgres_raw', 'pagamento_dinheiro') }}
)

select
    cast(id as varchar) as pagamento_id,
    valor as valor_brl,
    data_compra,
    descricao,
    comentario,
    metodo_pagamento,
    upper(categoria) as categoria_limpa,
    cast('pix' as varchar) as tipo_pagamento
from source_data