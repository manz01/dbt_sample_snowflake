/*------------------------------------------------------------------------------
Program:        T_STG_GO_1K.sql
Project:        dbt-sample-go-sales-snowflake
Description:    Staging model for GO Sales products transactions
                 with raw data from source
Input(s):       RAW.T_RAW_GO_1K
Output(s):      STG.T_STG_GO_1K
Author:         Manzar Ahmed
First Created:  Jun 2025
--------------------------------------------------------------------------------
Program history:
--------------------------------------------------------------------------------
Date        Programmer             Description
----------  ---------------------  ---------------------------------------------
2025-06-11  Manzar Ahmed           v0.01/Initial version
2025-07-11	Manzar Ahmed		   v0.02/changed to snowflake endpoint
------------------------------------------------------------------------------*/
{{ config(
    materialized = 'table',
    transient = true
) }}

select
    RETAILER_CODE,
    PRODUCT_NUMBER,
    TRANSACTION_DATE,
    QUANTITY

from {{ source('gosales_raw', 'T_RAW_GO_1K') }}

qualify row_number() over (
    partition by 
        RETAILER_CODE, 
        PRODUCT_NUMBER, 
        TRANSACTION_DATE, 
        QUANTITY
    order by 
        TRANSACTION_DATE desc
) = 1

order by 
    TRANSACTION_DATE,
    RETAILER_CODE, 
    PRODUCT_NUMBER