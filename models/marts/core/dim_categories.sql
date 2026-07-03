{{ config(materialized='table') }}

select distinct
    md5(concat(coalesce(tipo_gasto, ''), coalesce(grupo, ''), coalesce(categoria, ''), coalesce(subcategoria, ''))) as category_id,
    tipo_gasto,
    grupo,
    categoria as category_name,
    subcategoria as subcategory_name
from {{ ref('category_mapping') }}