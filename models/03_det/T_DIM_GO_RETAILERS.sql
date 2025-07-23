/*------------------------------------------------------------------------------
Program:        T_DIM_GO_RETAILERS
Project:        dbt-sample-go-sales-snowflake
Description:    SCD2 dimension model for GO Sales retailers
Input(s):       STG.T_STG_GO_RETAILERS
Output(s):      DET.T_DIM_GO_RETAILERS
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
2025-07-14  Manzar Ahmed           v0.05/changed to snowflake endpoint                                                                     
-------------------------------------------------------------------------------*/

{{ config(
    materialized = 'incremental',
    schema = 'DET',
    unique_key = 'DIM_RETAILER_SK',
    incremental_strategy = 'merge',
    pre_hook = ["create sequence if not exists DET.SEQ_DIM_RETAILER_SK start = 1 increment = 1"]
) }}

{% set vars = get_scd2_vars() %}
{% set start_ts = "cast('" ~ vars.start_ts ~ "' as timestamp)" %}
{% set end_ts = "cast('" ~ vars.end_ts ~ "' as timestamp)" %}
{% set high_date_ts = "cast('" ~ vars.high_date ~ "' as timestamp)" %}

with current_data as (

    select  
	    RETAILER_CODE,
		RETAILER_NAME,
		RETAILER_TYPE,
		COUNTRY,
		md5(
			coalesce(RETAILER_NAME, '') || '|' ||
			coalesce(RETAILER_TYPE, '') || '|' ||
			coalesce(COUNTRY, '')
			) as SCD2_HASH
			
    from {{ ref('T_STG_GO_RETAILERS') }}
	
)

{% if is_incremental() %},

existing_records as (

    select  
		DIM_RETAILER_SK,    
	    RETAILER_CODE,
		RETAILER_NAME,
		RETAILER_TYPE,
		COUNTRY,
		SCD2_HASH,
		START_TS,
		VERSION_NUMBER,
		CURRENT_VERSION,
		PRIOR_DIM_RETAILER_SK	
    from {{ this }}
	
    where CURRENT_VERSION = true
	
),

ordered_changes as (

    select      
	    c.RETAILER_CODE,
		c.RETAILER_NAME,
		c.RETAILER_TYPE,
		c.COUNTRY,
		c.SCD2_HASH,
		e.DIM_RETAILER_SK as PRIOR_DIM_RETAILER_SK,
		coalesce(e.VERSION_NUMBER, 0) + 1 as VERSION_NUMBER		
		
    from current_data c
	
    left join existing_records e
        on c.retailer_code = e.retailer_code
		
    where       
	    e.RETAILER_CODE is null
    or  c.SCD2_HASH != e.SCD2_HASH
	
    order by    
	    c.RETAILER_CODE
),

changes as (

    select  
	    DET.SEQ_DIM_RETAILER_SK.nextval as DIM_RETAILER_SK,
		oc.RETAILER_CODE,
		oc.RETAILER_NAME,
		oc.RETAILER_TYPE,
		oc.COUNTRY,
		oc.SCD2_HASH,
		{{ start_ts }} as START_TS,
		{{ high_date_ts }} as END_TS,
		oc.VERSION_NUMBER,
		TRUE as CURRENT_VERSION,
		oc.PRIOR_DIM_RETAILER_SK	
    from ordered_changes oc
),

updates as (

    select  
	    e.DIM_RETAILER_SK,
		e.RETAILER_CODE,
		e.RETAILER_NAME,
		e.RETAILER_TYPE,
		e.COUNTRY,
		e.SCD2_HASH,
		e.START_TS,
        {{ end_ts }} as END_TS,
		e.VERSION_NUMBER,
		false as CURRENT_VERSION,
		e.PRIOR_DIM_RETAILER_SK	
		
    from existing_records e
	
    join changes c
        on e.RETAILER_CODE = c.retailer_code
		
    where   
	    e.CURRENT_VERSION = true
		
)

select * from changes
union all
select * from updates


{% else %}

select      
    DET.SEQ_DIM_RETAILER_SK.nextval as DIM_RETAILER_SK,
	RETAILER_CODE,
	RETAILER_NAME,
	RETAILER_TYPE,
	COUNTRY,
	SCD2_HASH,
	{{ start_ts }}  as START_TS,
	{{ high_date_ts }} as END_TS,
	1::integer as version_number,
	true as CURRENT_VERSION,	
	-1::integer as PRIOR_DIM_RETAILER_SK

from current_data

order by    
    retailer_code

{% endif %}