/*------------------------------------------------------------------------------
Program:        T_STG_GO_METHOD.sql
Project:        dbt-sample-go-sales-snowflake
Description:    Staging model for GO Sales order methods
                 with raw data from source
Input(s):       RAW.T_RAW_GO_METHODS
Output(s):      STG.T_STG_GO_METHOD
Author:         Manzar Ahmed
First Created:  Jun 2025
--------------------------------------------------------------------------------
Program history:
--------------------------------------------------------------------------------
Date        Programmer             Description
----------  ---------------------  ---------------------------------------------
2025-06-11  Manzar Ahmed           v0.01/Initial version
2025-07-11  Manzar Ahmed           v0.02/changed to snowflake endpoint
------------------------------------------------------------------------------*/

{{ config(
    materialized = 'table',
    transient = true
) }}

select  
    ORDER_METHOD_CODE,  
    ORDER_METHOD_TYPE

from {{ source('gosales_raw', 'T_RAW_GO_METHODS') }}  

qualify row_number() over (
    partition by ORDER_METHOD_CODE, ORDER_METHOD_TYPE
    order by ORDER_METHOD_CODE desc
) = 1

order by ORDER_METHOD_CODE
