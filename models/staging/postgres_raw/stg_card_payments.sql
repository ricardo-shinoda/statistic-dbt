{{ config(materialized='view') }}

with source as (
    select 
        *,
        row_number() over (
            partition by 
                "Data de Compra",
                "Final do Cartão",
                "Descrição",
                coalesce("Parcela", 'Única'),
                "Valor (em R$)"
            order by arquivo_origem desc
        ) as rn
    from {{ source('postgres_raw', 'payment_card') }}
    where upper("Descrição") not like '%INCLUSAO DE PAGAMENTO%'
      and upper("Descrição") not like '%PAGAMENTO FATURA%'
      and upper("Descrição") not like '%PAGAMENTO EFETUADO%'
),

cleaned as (
    select
        md5(concat(
            coalesce("Data de Compra"::text, ''), 
            coalesce("Final do Cartão"::text, ''),
            coalesce("Descrição", ''), 
            coalesce("Parcela", 'Única'),
            coalesce("Valor (em R$)"::text, '0')
        )) as payment_id,
        
        to_date("Data de Compra", 'DD/MM/YYYY') as purchased_at,
        "Valor (em R$)"::numeric as amount_brl,
        
        "Descrição" as original_description,
        coalesce("Categoria", '') as bank_category,
        
        trim(regexp_replace(
            lower("Descrição"), 
            '^(pag\*|mp\*|ifd\*|itau\*|uber\*|pax\*|rec\*|ame\*|99food\s*\*|compra\s+).*?\s*', 
            ''
        )) as cleaned_description,
        
        'credit_card' as payment_type,
        false as is_internal_transfer,
        true as is_payment_transaction
    from source
    where rn = 1
),

matched_seed as (
    select distinct on (c.payment_id)
        c.*,
        r.tipo_gasto as seed_tipo_gasto,
        r.category_name as seed_category_name,
        r.subcategory_name1 as seed_subcategory_name1
    from cleaned c
    left join {{ ref('category_rules') }} r
        on c.original_description ilike '%' || r.pattern || '%'
    order by c.payment_id, length(r.pattern) desc
),

categorized as (
    select
        c.*,
        
        -- 1. TIPO DE GASTO (Seed -> Regras de Texto -> Fallback)
        coalesce(
            seed_tipo_gasto,
            case 
                when cleaned_description ilike '%drogasil%' 
                  or cleaned_description ilike '%drogal%' 
                  or cleaned_description ilike '%farmacia%' 
                  or cleaned_description ilike '%rd saude%'
                  or cleaned_description ilike '%posto%' 
                  or cleaned_description ilike '%abastec%'
                  or cleaned_description ilike '%ipiranga%' 
                  or cleaned_description ilike '%shell%' 
                  or cleaned_description ilike '%confianca%' 
                  or cleaned_description ilike '%tauste%'
                  or cleaned_description ilike '%pao de acucar%'
                  or cleaned_description ilike '%sams%' 
                  or cleaned_description ilike '%carrefour%' then 'essencial'
                else 'variável'
            end
        ) as tipo_gasto,

        -- 2. CATEGORIA PRINCIPAL (Seed -> Padrões -> Mapeamento exato das Categorias do C6)
        coalesce(
            seed_category_name,
            case
                -- Alimentação (Mercado e Comida Fora)
                when bank_category ilike '%restaurante%'
                  or bank_category ilike '%supermercados%'
                  or original_description ilike '%ifd%' 
                  or original_description ilike '%ifood%' 
                  or original_description ilike '%99food%'
                  or cleaned_description ilike '%restaurante%' 
                  or cleaned_description ilike '%bobs%' 
                  or cleaned_description ilike '%burger%' 
                  or cleaned_description ilike '%burguer%'
                  or cleaned_description ilike '%mcdonald%'
                  or cleaned_description ilike '%mc donald%'
                  or cleaned_description ilike '%outback%'
                  or cleaned_description ilike '%pizza%'
                  or cleaned_description ilike '%lanches%'
                  or cleaned_description ilike '%pastel%'
                  or cleaned_description ilike '%sorvete%'
                  or cleaned_description ilike '%churros%'
                  or cleaned_description ilike '%padaria%'
                  or cleaned_description ilike '%mercado%'
                  or cleaned_description ilike '%confianca%' 
                  or cleaned_description ilike '%sams%' 
                  or cleaned_description ilike '%tauste%'
                  or cleaned_description ilike '%pao de acucar%'
                  or cleaned_description ilike '%emporio prime%'
                  or cleaned_description ilike '%carrefour%' then 'alimentação'
                  
                -- Transporte
                when bank_category in ('Automotivo', 'Relacionados a Automotivo', 'Transporte')
                  or cleaned_description ilike '%uber%' 
                  or cleaned_description ilike '%99app%' 
                  or cleaned_description ilike '%abastec%'
                  or cleaned_description ilike '%posto%' 
                  or cleaned_description ilike '%ipiranga%' 
                  or cleaned_description ilike '%shell%' then 'transporte'
                  
                -- Saúde
                when bank_category in ('Assistência médica e odontológica', 'Aparelhos auditivos')
                  or cleaned_description ilike '%drogasil%' 
                  or cleaned_description ilike '%drogal%' 
                  or cleaned_description ilike '%rd saude%'
                  or cleaned_description ilike '%farmacia%' 
                  or cleaned_description ilike '%unimed%' then 'saúde'

                -- Educação
                when bank_category in ('Educacional', 'Foto / Fotocópia') then 'educação'
                  
                -- Moradia / Contas / Manutenção Casa
                when bank_category in ('Aluguel', 'Casa / Escritório Mobiliário', 'Consertos em Geral', 'Construção', 'Elétrico', 'Limpeza / Lavanderia', 'Materiais de construção para casa', 'Serviços de telecomunicações', 'TV por assinatura / Serviços de rádio') then 'moradia'

                -- Compras / Varejo (Todo o Varejo e Lojas do C6)
                when bank_category in ('Especialidade varejo', 'Departamento / Desconto', 'Vestuário / Roupas', 'Arte / Artesanato / Passatempo', 'Antigos / Peço Lojas', 'Representantes e Galerias de Arte')
                  or cleaned_description ilike '%amazon%'
                  or cleaned_description ilike '%mercadolivre%'
                  or cleaned_description ilike '%netshoes%'
                  or cleaned_description ilike '%shein%'
                  or cleaned_description ilike '%renner%'
                  or cleaned_description ilike '%marisa%'
                  or cleaned_description ilike '%havan%'
                  or cleaned_description ilike '%centauro%' then 'compras / varejo'

                -- Lazer / Bem Estar
                when bank_category in ('Entretenimento', 'Recreativo', 'T&E')
                  or cleaned_description ilike '%netflix%' 
                  or cleaned_description ilike '%spotify%' 
                  or cleaned_description ilike '%youtube%'
                  or cleaned_description ilike '%prime%' then 'lazer / bem estar'

                -- Contabilidade / Taxas / Seguros
                when bank_category in ('Seguro', 'Serviços financeiros', 'Marketing Direto') then 'contabilidade'

                else 'Não Classificado'
            end
        ) as category_name,

        -- 3. SUBCATEGORIA 1
        coalesce(
            seed_subcategory_name1,
            case
                when original_description ilike '%ifd%' 
                  or original_description ilike '%ifood%' 
                  or original_description ilike '%99food%'
                  or bank_category ilike '%restaurante%'
                  or cleaned_description ilike '%restaurante%'
                  or cleaned_description ilike '%bobs%' 
                  or cleaned_description ilike '%burger%' 
                  or cleaned_description ilike '%burguer%'
                  or cleaned_description ilike '%mcdonald%'
                  or cleaned_description ilike '%mc donald%'
                  or cleaned_description ilike '%outback%'
                  or cleaned_description ilike '%pizza%'
                  or cleaned_description ilike '%lanches%'
                  or cleaned_description ilike '%pastel%'
                  or cleaned_description ilike '%sorvete%'
                  or cleaned_description ilike '%churros%' then 'Comida Fora'

                when bank_category ilike '%supermercados%'
                  or cleaned_description ilike '%confianca%' 
                  or cleaned_description ilike '%sams%' 
                  or cleaned_description ilike '%tauste%' 
                  or cleaned_description ilike '%pao de acucar%'
                  or cleaned_description ilike '%emporio prime%'
                  or cleaned_description ilike '%carrefour%' then 'Mercado'

                when cleaned_description ilike '%uber%' 
                  or cleaned_description ilike '%99app%' then 'Motorista de App'

                when cleaned_description ilike '%posto%' 
                  or cleaned_description ilike '%abastec%'
                  or cleaned_description ilike '%ipiranga%' 
                  or cleaned_description ilike '%shell%' then 'Combustível'

                when cleaned_description ilike '%drogasil%' 
                  or cleaned_description ilike '%drogal%' 
                  or cleaned_description ilike '%rd saude%'
                  or cleaned_description ilike '%farmacia%' then 'Medicamento'

                when bank_category in ('Especialidade varejo', 'Departamento / Desconto') then 'Varejo Geral'
                when bank_category in ('Vestuário / Roupas') then 'Vestuário'

                else 'Não Especificado'
            end
        ) as subcategory_name1,

        -- 4. SUBCATEGORIA 2
        case
            when original_description ilike '%ifd%' 
              or original_description ilike '%ifood%' 
              or original_description ilike '%99food%' then 'Delivery'
            when bank_category ilike '%restaurante%'
              or cleaned_description ilike '%restaurante%'
              or cleaned_description ilike '%burger%' 
              or cleaned_description ilike '%burguer%'
              or cleaned_description ilike '%mcdonald%'
              or cleaned_description ilike '%mc donald%'
              or cleaned_description ilike '%outback%'
              or cleaned_description ilike '%pizza%'
              or cleaned_description ilike '%lanches%'
              or cleaned_description ilike '%pastel%'
              or cleaned_description ilike '%sorvete%'
              or cleaned_description ilike '%churros%' then 'Restaurante / Lanche'
            else 'Não Especificado'
        end as subcategory_name2

    from matched_seed c
)

select
    payment_id,
    amount_brl,
    purchased_at,
    payment_type,
    original_description as description,
    null as comments,
    
    coalesce(tipo_gasto, 'variável') as tipo_gasto,
    coalesce(category_name, 'Não Classificado') as category_name,
    coalesce(subcategory_name1, 'Não Especificado') as subcategory_name1,
    coalesce(subcategory_name2, 'Não Especificado') as subcategory_name2,
    
    is_internal_transfer,
    is_payment_transaction
from categorized