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