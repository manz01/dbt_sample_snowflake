/*-------------------------------------------------------------------------------
Program:        T_FCT_GO_SALES
Project:        dbt-sample-go-sales-snowflake
Description:    Fact table for GO Sales with surrogate keys from dimensions
Input(s):       STG.T_STG_GO_DAILY_SALES
                DET.T_DIM_GO_ORDER_METHODS
				DET.T_DIM_GO_PRODUCTS
				STG.T_DIM_GO_RETAILERS
Output(s):      FCT.T_FCT_GO_SALES
Author:         Manzar Ahmed
First Created:  Jun 2025
--------------------------------------------------------------------------------
Program history:
--------------------------------------------------------------------------------
Date        Programmer             Description
----------  ---------------------  ---------------------------------------------
2025-06-11  Manzar Ahmed           v0.01/Initial version
2025-07-14	Manzar Ahmed		   v0.02/changed to snowflake endpoint  
-------------------------------------------------------------------------------*/

{{ config(
    materialized='incremental',
    schema='DET',
    unique_key=['DIM_RETAILER_SK', 'DIM_PRODUCT_SK', 'DIM_ORDER_METHOD_SK', 'TRANSACTION_DATE'],
    incremental_strategy = 'merge',
    on_schema_change='sync_all_columns',
    pre_hook=["create sequence if not exists DET.SEQ_FCT_SALES_SK start = 1 increment = 1"],
    cluster_by=['TRANSACTION_DATE'] 
) }}

{%- set high_date = '9999-12-31 00:00:00' %}

with base as (
    select
        s.RETAILER_CODE,
        s.PRODUCT_NUMBER,
        s.ORDER_METHOD_CODE,
        s.TRANSACTION_DATE::date as TRANSACTION_DATE,
        s.QUANTITY,
        s.UNIT_PRICE,
        s.UNIT_SALE_PRICE
    from {{ ref('T_STG_GO_DAILY_SALES') }} as s
    order by
        s.TRANSACTION_DATE,
        s.RETAILER_CODE,
        s.PRODUCT_NUMBER,
        s.ORDER_METHOD_CODE
),

joined as (
    select
        DET.SEQ_FCT_SALES_SK.nextval as FCT_SALES_SK,
        r.DIM_RETAILER_SK,
        p.DIM_PRODUCT_SK,
        m.DIM_ORDER_METHOD_SK,
        b.TRANSACTION_DATE,
        b.QUANTITY,
        b.UNIT_PRICE,
        b.UNIT_SALE_PRICE,
        current_timestamp as CREATE_TS,
        current_timestamp as UPDATE_TS
    from base as b
        left join {{ ref('T_DIM_GO_RETAILERS') }} as r
            on b.RETAILER_CODE = r.RETAILER_CODE
            and r.CURRENT_VERSION = true
        left join {{ ref('T_DIM_GO_PRODUCTS') }} as p
            on b.PRODUCT_NUMBER = p.PRODUCT_NUMBER
            and p.CURRENT_VERSION = true
        left join {{ ref('T_DIM_GO_ORDER_METHODS') }} as m
            on b.ORDER_METHOD_CODE = m.ORDER_METHOD_CODE
)

select
    FCT_SALES_SK,
    DIM_RETAILER_SK,
    DIM_PRODUCT_SK,
    DIM_ORDER_METHOD_SK,
    TRANSACTION_DATE,
    QUANTITY,
    UNIT_PRICE,
    UNIT_SALE_PRICE,
    CREATE_TS,
    UPDATE_TS
from joined

{% if is_incremental() %}
where (
    DIM_RETAILER_SK,
    DIM_PRODUCT_SK,
    DIM_ORDER_METHOD_SK,
    TRANSACTION_DATE
) not in (
    select
        DIM_RETAILER_SK,
        DIM_PRODUCT_SK,
        DIM_ORDER_METHOD_SK,
        TRANSACTION_DATE
    from {{ this }}
)
{% endif %}

order by FCT_SALES_SK
