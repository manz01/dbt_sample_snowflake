/*------------------------------------------------------------------------------
Program:        T_DIM_GO_ORDER_METHODS.sql
Project:        dbt-sample-go-sales-snowflake
Description:    SCD1 dimension model for GO Sales order methods with surrogate
                key and audit columns
Input(s):       STG.T_STG_GO_METHODS
Output(s):      DET.T_DIM_GO_ORDER_METHODS
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
    materialized = 'incremental',
    schema = 'DET',
    unique_key = 'DIM_ORDER_METHOD_SK',
    incremental_strategy = 'merge',
    pre_hook = ["create sequence if not exists DET.SEQ_DIM_ORDER_METHOD_SK start = 1 increment = 1"]
) }}

with source_data as (
    select
        ORDER_METHOD_CODE,
        ORDER_METHOD_TYPE
    from {{ ref('T_STG_GO_METHODS') }}
    order by ORDER_METHOD_CODE
)

{% if is_incremental() %}

    ,existing_data as (
        select
            ORDER_METHOD_CODE,
            ORDER_METHOD_TYPE,
            DIM_ORDER_METHOD_SK,
            CREATE_TS,
            UPDATE_TS
        from {{ this }}
    )
    , new_or_changed as (
        select
            s.ORDER_METHOD_CODE,
            s.ORDER_METHOD_TYPE,
            DET.SEQ_DIM_ORDER_METHOD_SK.nextval as DIM_ORDER_METHOD_SK,
            coalesce(e.CREATE_TS, current_timestamp) as CREATE_TS,
            current_timestamp as UPDATE_TS
        from source_data as s
        left join existing_data as e
            on s.ORDER_METHOD_CODE = e.ORDER_METHOD_CODE
        where
            e.ORDER_METHOD_CODE is null
            or s.ORDER_METHOD_TYPE != e.ORDER_METHOD_TYPE
    )

    select * from new_or_changed

{% else %}

select
    DET.SEQ_DIM_ORDER_METHOD_SK.nextval as DIM_ORDER_METHOD_SK,
    ORDER_METHOD_CODE,
    ORDER_METHOD_TYPE,
    current_timestamp as CREATE_TS,
    current_timestamp as UPDATE_TS
from source_data

{% endif %}
