/*-------------------------------------------------------------------------------
Program:        T_STG_GO_PRODUCTS.sql
Project:        dbt-sample-go-sales-snowflake
Description:    Staging model for GO Sales products
                with raw data from source
Input(s):       RAW.T_RAW_GO_PRODUCTS
Output(s):      STG.T_STG_GO_PRODUCTS
Author:         Manzar Ahmed
First Created:  Jun 2025
--------------------------------------------------------------------------------
Program history:
--------------------------------------------------------------------------------
Date        Programmer             Description
----------  ---------------------  ---------------------------------------------
2025-06-11  Manzar Ahmed           v0.01/Initial version
2025-07-11  Manzar Ahmed           v0.02/changed to snowflake endpoint
-------------------------------------------------------------------------------*/

{{ config(
    materialized = 'table',
    transient = true
) }}


select  
    PRODUCT_NUMBER, 
    PRODUCT_LINE, 
    PRODUCT_TYPE,  
    PRODUCT, 
    PRODUCT_BRAND, 
    PRODUCT_COLOR, 
    UNIT_COST, 
    UNIT_PRICE,

from {{ source('gosales_raw', 'T_RAW_GO_PRODUCTS') }}  

qualify row_number() over (
    partition by 
        PRODUCT_NUMBER, 
		PRODUCT_LINE, 
		PRODUCT_TYPE,  
		PRODUCT, 
		PRODUCT_BRAND, 
		PRODUCT_COLOR
    order by
        PRODUCT_NUMBER desc
) = 1

order by PRODUCT_NUMBER