MODEL (
  name vulcan_demo.stg_products,
  kind VIEW,
  grains product_id,
  profiles (
    product_sk,
    product_id,
    product_name,
    category,
    list_price,
    supplier_id,
    supplier_name,
    supplier_regssion_id
  )
);

@WITH(TRUE) p AS (
  SELECT
    p.product_id,
    p.name,
    p.category,
    p.price,
    p.supplier_id
  FROM vulcan_demo.products AS p
), s AS (
  SELECT
    supplier_id,
    name AS supplier_name,
    region_id
  FROM vulcan_demo.suppliers
)
SELECT
  @GENERATE_SURROGATE_KEY(p.product_id, p.supplier_id) AS product_sk,
  p.product_id::INT,
  p.name::TEXT AS product_name,
  p.category::TEXT,
  p.price::DECIMAL(10, 4) AS list_price,
  s.supplier_id::INT,
  s.supplier_name::TEXT,
  s.region_id::INT AS supplier_region_id
FROM p
LEFT @JOIN(TRUE) s
  ON s.supplier_id = p.supplier_id