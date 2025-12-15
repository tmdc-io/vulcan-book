/* Slowly-evolving style (type 1 for simplicity), keys + region */
MODEL (
  name vulcan_demo.dim_customer,
  kind FULL,
  grains customer_sk,
  description 'Customer dimension with surrogate key and current attributes.',
  profiles (customer_sk, customer_id, customer_name, email, region_id, region_name),
  column_descriptions (
    customer_sk = 'Customer Surrogate Key',
    customer_id = 'Customer ID',
    customer_name = 'Customer Name',
    email = 'Email Address',
    region_id = 'Region ID',
    region_name = 'Region Name'
  )
);

SELECT
  sc.customer_sk::TEXT,
  sc.customer_id::INT,
  sc.customer_name::TEXT,
  sc.email::TEXT,
  sc.region_id::INT,
  sc.region_name::TEXT
FROM vulcan_demo.stg_customers AS sc