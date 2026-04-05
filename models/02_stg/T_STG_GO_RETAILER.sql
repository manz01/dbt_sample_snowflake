/*------------------------------------------------------------------------------
Program:        T_STG_GO_RETAILER.sql
Project:        dbt-sample-go-sales-snowflake
Description:    Staging model for GO Sales retailers
                with raw data from source
Input(s):       RAW.T_RAW_GO_RETAILERS
Output(s):      STG.T_STG_GO_RETAILER
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
    RETAILER_NAME, 
    RETAILER_TYPE, 
    COUNTRY

from {{ source('gosales_raw', 'T_RAW_GO_RETAILERS') }}  

qualify row_number() over (
    partition by 
        RETAILER_CODE, 
        RETAILER_NAME, 
        RETAILER_TYPE, 
        COUNTRY
    order by
        RETAILER_CODE desc
) = 1

order by RETAILER_CODE
