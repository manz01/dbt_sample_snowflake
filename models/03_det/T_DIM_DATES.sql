/*------------------------------------------------------------------------------
Program:        T_DIM_DATES.sql
Project:        dbt-sample-go-sales-snowflake
Description:    Dimension model for GO Sales dates with various date attributes
                 including year, month, day, week, and weekend/weekday flags
Input(s):       date_span
Output(s):      DET.T_DIM_DATES
Author:         Manzar Ahmed
First Created:  Jul 2025
--------------------------------------------------------------------------------
Program history:
--------------------------------------------------------------------------------
Date        Programmer             Description
----------  ---------------------  ---------------------------------------------
2025-07-06  Manzar Ahmed           v0.01/Initial version
2025-07-14	Manzar Ahmed		   v0.02/changed to snowflake endpoint
-------------------------------------------------------------------------------*/

{{ config(
    materialized = 'table',
    schema = 'DET'
) }}

with date_span as (
    select 
        dateadd(day, seq4(), date '2000-01-01') as FULL_DATE
    from table(generator(rowcount => 365 * 100))
),

dim_dates as (
    select 
        cast(FULL_DATE as date) as DATE_KEY,
        FULL_DATE,
        year(FULL_DATE) as YEAR,
        month(FULL_DATE) as MONTH,
        day(FULL_DATE) as DAY,
        weekofyear(FULL_DATE) as WEEK_OF_YEAR,
        dayofweek(FULL_DATE) as WEEKDAY_NUMBER,
        dayofyear(FULL_DATE) as DAY_OF_YEAR,
        to_varchar(FULL_DATE::date, 'YYYY-MM') as WEEK_LABEL,
        to_char(FULL_DATE, 'YYYY') || '-' || lpad(to_char(month(FULL_DATE)), 2, '0')  as MONTH_LABEL,
        to_char(FULL_DATE, 'YYYY') || '-Q' || to_char(quarter(FULL_DATE)) as QUARTER_LABEL,
        case when dayofweek(FULL_DATE) in (1, 7) then true else false end as IS_WEEKEND,
        case when dayofweek(FULL_DATE) between 2 and 6 then true else false end as IS_WEEKDAY
    from date_span
)

select * from dim_dates
order by FULL_DATE