/*-------------------------------------------------------------------------------
Program:        T_MRT_GO_SALES.sql
Project:        dbt-sample-go-sales-snowflake
Description:    Mart sales model combining fact and dimension tables
Input(s):       DET.T_FCT_GO_SALES
                DET.T_DIM_GO_ORDER_METHOD
                DET.T_DIM_GO_PRODUCT
                DET.T_DIM_RETAILER
Output(s):      MRT.T_MRT_GO_SALES
Author:         Manzar Ahmed
First Created:  Jun 2025
--------------------------------------------------------------------------------
Program history:
--------------------------------------------------------------------------------
Date        Programmer             Description
----------  ---------------------  ---------------------------------------------
2025-06-11  Manzar Ahmed           v0.01/Initial version
2025-07-16	Manzar Ahmed		   v0.02/changed to snowflake endpoint  
-------------------------------------------------------------------------------*/

with fact as (
    select *
    from {{ ref('T_FCT_GO_SALES') }}
),

order_methods as (
    select *
    from {{ ref('T_DIM_GO_ORDER_METHODS') }}
),

products as (
    select *
    from {{ ref('T_DIM_GO_PRODUCTS') }}
    where CURRENT_VERSION = true
),

retailers as (
    select *
    from {{ ref('T_DIM_GO_RETAILERS') }}
    where CURRENT_VERSION = true
)

select
    -- Fact fields
    f.FCT_SALES_SK,
    f.TRANSACTION_DATE,
    f.QUANTITY,
    f.UNIT_PRICE,
    f.UNIT_SALE_PRICE,

    -- Order Method dimension
    om.ORDER_METHOD_CODE,
    om.ORDER_METHOD_TYPE,

    -- Product dimension
    p.PRODUCT_NUMBER,
    p.PRODUCT_LINE,
    p.PRODUCT_TYPE,
    p.PRODUCT,
    p.PRODUCT_BRAND,
    p.PRODUCT_COLOR,

    -- Retailer dimension
    r.RETAILER_CODE,
    r.RETAILER_NAME,
    r.COUNTRY as RETAILER_COUNTRY,
    r.RETAILER_TYPE

from fact as f
left join order_methods as om
    on f.DIM_ORDER_METHOD_SK = om.DIM_ORDER_METHOD_SK

left join products as p
    on f.DIM_PRODUCT_SK = p.DIM_PRODUCT_SK

left join retailers as r
    on f.DIM_RETAILER_SK = r.DIM_RETAILER_SK
