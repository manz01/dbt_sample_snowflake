/*-------------------------------------------------------------------------------------
  DBT Macro:    GO Sales Raw Load to Snowflake from S3 Stage
  Author:       Manzar Ahmed
  Date:         Jul 2025

  Description:
  This set of DBT macros loads raw GO Sales CSV files from an S3 external stage into 
  Snowflake tables. Each macro corresponds to a specific file and target table.

  How it works:
  - The `load_csv_to_snowflake_and_create_table` macro:
      - Creates or replaces a target table in Snowflake using a provided schema.
      - Loads CSV data from an S3 stage path using the Snowflake `COPY INTO` command.
      - The file format expects:
          - CSV with headers
          - Fields optionally enclosed in double quotes
          - Dates in 'DD/MM/YYYY' format
          - Errors on column count mismatch to be raised
          - Load to continue on row-level errors

  DBT Commands to run (in order):
      dbt run-operation load_raw_go_1k
      dbt run-operation load_raw_go_methods
      dbt run-operation load_raw_go_products
      dbt run-operation load_raw_go_retailers
      dbt run-operation load_raw_go_daily_sales

  Expected Stage:
      GOS01.RAW.GO_SALES_STAGE
--------------------------------------------------------------------------------------*/
/*******************************************************************************
Macro Name:          dbo.usp_DoSomeStuff
Create Date:        2018-01-25
Author:             Joe Expert
Description:        Verbose description of what the query does goes here. Be specific and don't be
                    afraid to say too much. More is better, than less, every single time. Think about
                    "what, when, where, how and why" when authoring a description.
Call by:            [schema.usp_ProcThatCallsThis]
                    [Application Name]
                    [Job]
                    [PLC/Interface]
Affected table(s):  [schema.TableModifiedByProc1]
                    [schema.TableModifiedByProc2]
Used By:            Functional Area this is use in, for example, Payroll, Accounting, Finance
Parameter(s):       @param1 - description and usage
                    @param2 - description and usage
Usage:              EXEC dbo.usp_DoSomeStuff
                        @param1 = 1,
                        @param2 = 3,
                        @param3 = 2
                    Additional notes or caveats about this object, like where is can and cannot be run, or
                    gotchas to watch for when using it.
****************************************************************************************************
SUMMARY OF CHANGES
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2012-04-27          John Usdaworkhur    Move Z <-> X was done in a single step. Warehouse does not
                                        allow this. Converted to two step process.
                                        Z <-> 7 <-> X
                                            1) move class Z to class 7
                                            2) move class 7 to class X

2018-03-22          Maan Widaplan       General formatting and added header information.
2018-03-22          Maan Widaplan       Added logic to automatically Move G <-> H after 12 months.
***************************************************************************************************/

{% macro load_csv_to_snowflake_and_create_table(table_name, file_name, columns, stage) %}
    {% set full_table = target.database ~ '.' ~ target.schema ~ '.' ~ table_name %}

    {% do run_query("CREATE OR REPLACE TABLE " ~ full_table ~ " (" ~ columns ~ ");") %}

    {% do run_query("COPY INTO " ~ full_table ~ "
        FROM @" ~ stage ~ "/" ~ file_name ~ "
        FILE_FORMAT = (
            TYPE = 'CSV',
            FIELD_OPTIONALLY_ENCLOSED_BY = '\"',
            SKIP_HEADER = 1,
            DATE_FORMAT = 'DD/MM/YYYY',
            ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
        )
        ON_ERROR = 'CONTINUE';") %}

    {{ return("Table created and loaded: " ~ full_table) }}
{% endmacro %}

{% macro load_raw_go_1k() %}
    {% set table_name = "T_RAW_GO_1K" %}
    {% set file_name = "go_1k.csv" %}
    {% set columns = """
        RETAILER_CODE BIGINT,
        PRODUCT_NUMBER BIGINT,
        TRANSACTION_DATE DATE,
        QUANTITY BIGINT
    """ %}
    {% set stage = "GOS01.RAW.GO_SALES_STAGE" %}

    {{ load_csv_to_snowflake_and_create_table(table_name, file_name, columns, stage) }}
{% endmacro %}

{% macro load_raw_go_methods() %}
    {% set table_name = "T_RAW_GO_METHODS" %}
    {% set file_name = "go_methods.csv" %}
    {% set columns = """
        ORDER_METHOD_CODE BIGINT,
        ORDER_METHOD_TYPE VARCHAR
    """ %}
    {% set stage = "GOS01.RAW.GO_SALES_STAGE" %}

    {{ load_csv_to_snowflake_and_create_table(table_name, file_name, columns, stage) }}
{% endmacro %}

{% macro load_raw_go_products() %}
    {% set table_name = "T_RAW_GO_PRODUCTS" %}
    {% set file_name = "go_products.csv" %}
    {% set columns = """
        PRODUCT_NUMBER BIGINT,
        PRODUCT_LINE VARCHAR,
        PRODUCT_TYPE VARCHAR,
        PRODUCT VARCHAR,
        PRODUCT_BRAND VARCHAR,
        PRODUCT_COLOR VARCHAR,
        UNIT_COST DOUBLE,
        UNIT_PRICE DOUBLE
    """ %}
    {% set stage = "GOS01.RAW.GO_SALES_STAGE" %}

    {{ load_csv_to_snowflake_and_create_table(table_name, file_name, columns, stage) }}
{% endmacro %}

{% macro load_raw_go_retailers() %}
    {% set table_name = "T_RAW_GO_RETAILERS" %}
    {% set file_name = "go_retailers.csv" %}
    {% set columns = """
        RETAILER_CODE BIGINT,
        RETAILER_NAME VARCHAR,
        RETAILER_TYPE VARCHAR,
        COUNTRY VARCHAR
    """ %}
    {% set stage = "GOS01.RAW.GO_SALES_STAGE" %}

    {{ load_csv_to_snowflake_and_create_table(table_name, file_name, columns, stage) }}
{% endmacro %}

{% macro load_raw_go_daily_sales() %}
    {% set table_name = "T_RAW_GO_DAILY_SALES" %}
    {% set file_name = "go_daily_sales.csv" %}
    {% set columns = """
        RETAILER_CODE BIGINT,
        PRODUCT_NUMBER BIGINT,
        ORDER_METHOD_CODE BIGINT,
        TRANSACTION_DATE DATE,
        QUANTITY BIGINT,
        UNIT_PRICE DOUBLE,
        UNIT_SALE_PRICE DOUBLE
    """ %}
    {% set stage = "GOS01.RAW.GO_SALES_STAGE" %}

    {{ load_csv_to_snowflake_and_create_table(table_name, file_name, columns, stage) }}
{% endmacro %}