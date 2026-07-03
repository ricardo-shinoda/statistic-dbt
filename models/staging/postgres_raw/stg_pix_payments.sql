with source_data as (
    select * from {{ source('postgres_raw', 'payment_pix') }}
),

mapped as (
    select
        -- Chave primária transacional
        md5(cast(s.data_compra as varchar) || s.descricao || cast(s.valor as varchar) || s.arquivo_origem) as payment_id,
        cast(s.data_compra as date) as purchased_at,
        lower(cast(s.dia_semana as varchar)) as week_day_raw,
        
        lower(s.descricao) as description,
        s.valor as amount_brl,
        lower(s.comentario) as comments,
        
        -- Mantém os metadados fixos
        cast('pix' as varchar) as payment_type,
        true as is_payment_transaction,

        -- Mapeamento inteligente da nova semente de 4 níveis
        m.tipo_gasto,
        m.grupo,
        m.categoria as category_name,
        m.subcategoria as subcategory_name,
        
        -- Regra de transferências internas
        case 
            when lower(s.descricao) ilike '%fatura%' then true
            when lower(s.descricao) ilike '%c6 bank%' then true
            when upper(s.categoria) = 'PAGAMENTOS' and upper(s.subcategoria) = 'CARTÃO DE CRÉDITO' then true
            else false
        end as is_internal_transfer

    from source_data s
    -- O JOIN mágico que estava faltando para resolver o erro do alias "m"
    left join {{ ref('category_mapping') }} m 
        on lower(s.descricao) like concat('%', lower(m.search_term), '%')
)

select
    payment_id,
    amount_brl,
    purchased_at,
    payment_type,
    description,
    comments,
    
    -- Fallback caso o termo do Pix não dê match com nenhuma linha da semente
    coalesce(tipo_gasto, 'Variável') as tipo_gasto,
    coalesce(grupo, 'Outros') as grupo,
    coalesce(category_name, 'Não Classificado') as category_name,
    coalesce(subcategory_name, 'Não Classificado') as subcategory_name,
    
    is_internal_transfer,
    is_payment_transaction
from mapped