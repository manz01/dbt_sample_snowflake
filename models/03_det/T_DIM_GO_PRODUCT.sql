/*------------------------------------------------------------------------------
Program:        T_DIM_GO_PRODUCT.sql
Project:        dbt-sample-go-sales-snowflake
Description:    SCD2 dimension model for GO Sales products with surrogate key 
                and change hash
Input(s):       STG.T_STG_GO_PRODUCT
Output(s):      DET.T_DIM_GO_PRODUCT
Author:         Manzar Ahmed
First Created:  Jun 2025
--------------------------------------------------------------------------------
Program history:
--------------------------------------------------------------------------------
Date        Programmer             Description
----------  ---------------------  ---------------------------------------------
2025-06-11  Manzar Ahmed           v0.01/Initial version
2025-06-23  Manzar Ahmed           v0.02/Utilising SCD2 vars for start and end 
                                   timestamps
2025-06-23  Manzar Ahmed           v0.03/SonarQube issues fixed:  
                                   Define a constant instead of duplicating this 
                                   literal 5 times (plsql:S1192)    
2025-07-07  Manzar Ahmed           v0.04/Added version number, current_version 
                                   and prior surrogate key to SCD2        
2025-07-14  Manzar Ahmed           v0.05/changed to snowflake endpoint                                                                                       
-------------------------------------------------------------------------------*/
{{ config(
    materialized = 'incremental',
    schema = 'DET',
    unique_key = ['DIM_PRODUCT_SK'],
	incremental_strategy = 'merge',
    pre_hook = ["create sequence if not exists DET.SEQ_DIM_PRODUCT_SK start = 1 increment = 1"]	
) }}

{% set vars = get_scd2_vars() %}
{% set start_ts = "cast('" ~ vars.start_ts ~ "' as timestamp)" %}
{% set end_ts = "cast('" ~ vars.end_ts ~ "' as timestamp)" %}
{% set high_date_ts = "cast('" ~ vars.high_date ~ "' as timestamp)" %}

with current_data as (
    select  
	    PRODUCT_NUMBER,
		PRODUCT_LINE,
		PRODUCT_TYPE,
		PRODUCT,
		PRODUCT_BRAND,
		PRODUCT_COLOR,
		UNIT_COST,
		UNIT_PRICE,
		md5(
			coalesce(PRODUCT_LINE, '') || '|' ||
			coalesce(PRODUCT_TYPE, '') || '|' ||
			coalesce(PRODUCT, '') || '|' ||
			coalesce(PRODUCT_BRAND, '') || '|' ||
			coalesce(PRODUCT_COLOR, '') || '|' ||
			coalesce(cast(UNIT_COST as varchar), '') || '|' ||
			coalesce(cast(UNIT_PRICE as varchar), '')
		) as SCD2_HASH
    from {{ ref('T_STG_GO_PRODUCT') }}
)

{% if is_incremental() %},

existing_records as (
    select  
	    DIM_PRODUCT_SK,
		PRODUCT_NUMBER,
		PRODUCT_LINE,
		PRODUCT_TYPE,
		PRODUCT,
		PRODUCT_BRAND,
		PRODUCT_COLOR,
		UNIT_COST,
		UNIT_PRICE,
		SCD2_HASH,
		START_TS,
		END_TS,
		VERSION_NUMBER,
		CURRENT_VERSION,
		PRIOR_DIM_PRODUCT_SK
    from {{ this }}
    where   CURRENT_VERSION = true
),

ordered_changes as (
    select      
	    c.PRODUCT_NUMBER,
		c.PRODUCT_LINE,
		c.PRODUCT_TYPE,
		c.PRODUCT,
		c.PRODUCT_BRAND,
		c.PRODUCT_COLOR,
		c.UNIT_COST,
		c.UNIT_PRICE,
		c.SCD2_HASH,
		e.DIM_PRODUCT_SK as PRIOR_DIM_PRODUCT_SK,
		coalesce(e.VERSION_NUMBER, 0) + 1 as VERSION_NUMBER
    from current_data c
    left join existing_records e
    on c.PRODUCT_NUMBER = e.PRODUCT_NUMBER
    where 
	    e.PRODUCT_NUMBER is null
    or  c.SCD2_HASH != e.SCD2_HASH
    order by 
	    c.PRODUCT_NUMBER
),

changes as (
    select      
	    DET.SEQ_DIM_PRODUCT_SK.nextval as DIM_PRODUCT_SK,
		oc.PRODUCT_NUMBER,
		oc.PRODUCT_LINE,
		oc.PRODUCT_TYPE,
		oc.PRODUCT,
		oc.PRODUCT_BRAND,
		oc.PRODUCT_COLOR,
		oc.UNIT_COST,
		oc.UNIT_PRICE,
		oc.SCD2_HASH,
		{{ start_ts }} as START_TS,
		{{ high_date_ts }} as END_TS,
		oc.VERSION_NUMBER,
		TRUE as CURRENT_VERSION,
		oc.PRIOR_DIM_PRODUCT_SK
    from ordered_changes oc
),

updates as (
    select      
	    e.DIM_PRODUCT_SK,
		e.PRODUCT_NUMBER,
		e.PRODUCT_LINE,
		e.PRODUCT_TYPE,
		e.PRODUCT,
		e.PRODUCT_BRAND,
		e.PRODUCT_COLOR,
		e.UNIT_COST,
		e.UNIT_PRICE,
		e.SCD2_HASH,
		e.START_TS,
		{{ end_ts }} as END_TS,
		e.VERSION_NUMBER,
		false as CURRENT_VERSION,
		e.PRIOR_DIM_PRODUCT_SK
    from existing_records e
    join changes c
    on e.PRODUCT_NUMBER = c.PRODUCT_NUMBER
    where       
	   e.CURRENT_VERSION = true
)

select * from changes
union all
select * from updates

{% else %}

select  
    DET.SEQ_DIM_PRODUCT_SK.nextval as DIM_PRODUCT_SK,
	PRODUCT_NUMBER,
	PRODUCT_LINE,
	PRODUCT_TYPE,
	PRODUCT,
	PRODUCT_BRAND,
	PRODUCT_COLOR,
	UNIT_COST,
	UNIT_PRICE,
	SCD2_HASH,
	{{ start_ts }} as START_TS,
	{{ high_date_ts }} as END_TS,
	1::integer as version_number,
	true as CURRENT_VERSION,
	-1::integer as PRIOR_DIM_PRODUCT_SK

from current_data

order by 
   PRODUCT_NUMBER

{% endif %}
