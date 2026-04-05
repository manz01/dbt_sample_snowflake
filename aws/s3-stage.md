```sql
CREATE OR REPLACE STORAGE INTEGRATION gosales_s3
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::123456789012:role/snowflake-access-role'
  STORAGE_ALLOWED_LOCATIONS = ('s3://go-sales/');


  DESC INTEGRATION gosales_s3;

```

|property|property_type|property_value|property_default|
|-|-|-|-|
|ENABLED|Boolean|true|false|
|STORAGE_PROVIDER|String|S3||
|STORAGE_ALLOWED_LOCATIONS|List,s3://go-sales/|[]||
|STORAGE_BLOCKED_LOCATIONS,List||[]|
|STORAGE_AWS_IAM_USER_ARN|String|arn:aws:iam::724772052480:user/externalstages/cilen90000||
STORAGE_AWS_ROLE_ARN,String,arn:aws:iam::123456789012:role/snowflake-access-role,
STORAGE_AWS_EXTERNAL_ID,String,YO19174_SFCRole=4_fMO0LOpe1w+L+dSzEeUZW6dWcuM=,
USE_PRIVATELINK_ENDPOINT,Boolean,false,false
COMMENT,String,,


```sql
USE DATABASE gos01;

CREATE OR REPLACE STAGE go_sales_stage
URL = 's3://go-sales/'
STORAGE_INTEGRATION = gosales_s3;


LIST @go_sales_stage;
```


name,size,md5,last_modified
s3://go-sales/go_1k.csv,25923,8a5042551bbd4cb4d5058511e059e5dc,"Wed, 9 Jul 2025 19:17:06 GMT"
s3://go-sales/go_daily_sales.csv,6058951,960eebdea858c6e4f88ce90713f97cd7,"Wed, 9 Jul 2025 19:17:10 GMT"
s3://go-sales/go_methods.csv,143,e1b0bbcb27e61d22c86db45e2aea75dd,"Wed, 9 Jul 2025 19:17:10 GMT"
s3://go-sales/go_products.csv,20402,476c09b0e383bebe7cf861baedffe662,"Wed, 9 Jul 2025 19:17:10 GMT"
s3://go-sales/go_retailers.csv,26334,2270f9fa1c82d1a0c44e2cfa15577f58,"Wed, 9 Jul 2025 19:17:11 GMT"
