MODEL (
  name vulcan_demo.stg_customers,
  kind VIEW,
  grains customer_id
);

@WITH(TRUE) c AS (
  SELECT
    c.customer_id,
    c.region_id,
    c.name,
    c.email
  FROM vulcan_demo.customers AS c
), r AS (
  SELECT
    region_id,
    region_name
  FROM vulcan_demo.regions
)
SELECT
  @GENERATE_SURROGATE_KEY(c.customer_id, c.email) AS customer_sk,
  c.customer_id::INT,
  c.email::TEXT,
  COALESCE(c.name, 'Sample Customer')::TEXT AS customer_name,
  r.region_name::TEXT AS region_name,
  r.region_id::INT
FROM c
LEFT @JOIN(TRUE) r
  ON r.region_id = c.region_id