/*-------------------------------------------------------------------------------
Program:        T_STG_GO_DAILY_SALES.sql
Project:        dbt-sample-go-sales-snowflake
Description:    Staging model for GO Sales products daily sales
                with raw data from source
Input(s):       RAW.T_RAW_GO_DAILY_SALES
Output(s):      STG.T_STG_GO_DAILY_SALES
Author:         Manzar Ahmed
First Created:  Jun 2025
--------------------------------------------------------------------------------
Program history:
--------------------------------------------------------------------------------
Date        Programmer             Description
----------  ---------------------  ---------------------------------------------
2025-06-11  Manzar Ahmed           v0.01/Initial version
2025-07-11	Manzar Ahmed		   v0.02/changed to snowflake endpoint
-------------------------------------------------------------------------------*/

{{ config(
    materialized = 'table',
    transient = true
) }}

select    
    RETAILER_CODE,
    PRODUCT_NUMBER,
    ORDER_METHOD_CODE,
    TRANSACTION_DATE,
    QUANTITY,
    CAST(UNIT_PRICE AS NUMBER(18,2)) AS UNIT_PRICE,
    CAST(UNIT_SALE_PRICE AS NUMBER(18,2)) AS UNIT_SALE_PRICE

from {{ source('gosales_raw', 'T_RAW_GO_DAILY_SALES') }} 

order by 
    TRANSACTION_DATE,
    RETAILER_CODE, 
    PRODUCT_NUMBER, 
    ORDER_METHOD_CODE
    