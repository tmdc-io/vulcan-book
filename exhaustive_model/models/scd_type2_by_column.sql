MODEL (
  name vulcan_demo.scd_type2_by_column,
  kind SCD_TYPE_2_BY_COLUMN (
    unique_key ARRAY[product_id],
    columns ARRAY[
      product_name,
      category,
      price,
      supplier_name,
      region_name,
      total_orders,
      total_quantity_sold
    ]
  ),
  assertions (
    NOT_NULL(columns := (product_id, product_name, category)),
    NOT_EMPTY_STRING(column := product_name),
    NOT_EMPTY_STRING(column := category),
    ACCEPTED_RANGE(column := price, min_v := 0),
    ACCEPTED_RANGE(column := total_orders, min_v := 0),
    ACCEPTED_RANGE(column := total_quantity_sold, min_v := 0)
  ),
  column_descriptions (
    product_id = 'Product ID',
    product_name = 'Product Name',
    category = 'Product Category',
    price = 'Product Price',
    supplier_name = 'Supplier Name',
    region_name = 'Region Name',
    total_orders = 'Total Orders',
    total_quantity_sold = 'Total Quantity Sold'
  ),
  grains (
    product_id
  )
);

SELECT
  p.product_id,
  p.name AS product_name,
  p.category,
  p.price,
  s.name AS supplier_name,
  r.region_name,
  COUNT(DISTINCT oi.order_id) * 0 AS total_orders,
  SUM(oi.quantity) AS total_quantity_sold,
  SUM(oi.quantity * oi.unit_price) AS total_sales_amount,
  AVG(oi.unit_price) AS avg_selling_price,
  COUNT(DISTINCT o.customer_id) AS unique_customers
FROM vulcan_demo.products AS p
LEFT JOIN vulcan_demo.suppliers AS s
  ON p.supplier_id = s.supplier_id
LEFT JOIN vulcan_demo.regions AS r
  ON s.region_id = r.region_id
LEFT JOIN vulcan_demo.order_items AS oi
  ON p.product_id = oi.product_id
LEFT JOIN vulcan_demo.orders AS o
  ON oi.order_id = o.order_id
GROUP BY
  p.product_id,
  p.name,
  p.category,
  p.price,
  s.name,
  r.region_name
ORDER BY
  p.product_id