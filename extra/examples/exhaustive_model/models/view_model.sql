MODEL (
  name vulcan_demo.view_model,
  kind VIEW,
  start '2025-01-01',
  grains (
    warehouse_performance_key
  ),
  assertions (
    UNIQUE_VALUES(columns := warehouse_performance_key),
    NOT_NULL(columns := (warehouse_id, warehouse_name, order_date, warehouse_performance_key)),
    NOT_EMPTY_STRING(column := (
      warehouse_name
    )),
    ACCEPTED_RANGE(column := total_transactions, min_v := 0),
    ACCEPTED_RANGE(column := total_quantity_sold, min_v := 0),
    ACCEPTED_RANGE(column := total_sales_amount, min_v := 0),
    ACCEPTED_RANGE(column := unique_customers, min_v := 0),
    ACCEPTED_RANGE(column := avg_order_value, min_v := 0),
    ACCEPTED_RANGE(column := revenue_per_customer, min_v := 0),
    ACCEPTED_VALUES(
      column := warehouse_performance_tier,
      is_in := ('High Performing', 'Medium Performing', 'Low Performing')
    )
  ),
  column_descriptions (
    warehouse_id = 'Warehouse ID',
    warehouse_name = 'Warehouse Name',
    region_name = 'Region Name',
    order_date = 'Order Date',
    total_transactions = 'Total Transactions',
    total_quantity_sold = 'Total Quantity Sold',
    total_sales_amount = 'Total Sales Amount',
    unique_customers = 'Unique Customers',
    unique_products_sold = 'Unique Products Sold',
    avg_order_value = 'Average Order Value',
    revenue_per_customer = 'Revenue Per Customer',
    warehouse_performance_tier = 'Warehouse Performance Tier'
  ),
  profiles (
    warehouse_id,
    warehouse_name,
    region_name,
    order_date,
    warehouse_performance_key,
    total_transactions,
    total_quantity_sold,
    total_sales_amount,
    avg_transaction_value,
    unique_customers,
    unique_products_sold,
    avg_order_value,
    revenue_per_customer,
    warehouse_performance_tier
  )
);

SELECT
  w.warehouse_id,
  w.name AS warehouse_name,
  r.region_name,
  o.order_date,
  CONCAT(w.warehouse_id::TEXT, '_', o.order_date::TEXT) AS warehouse_performance_key,
  COUNT(DISTINCT o.order_id) AS total_transactions,
  SUM(oi.quantity) AS total_quantity_sold,
  SUM(oi.quantity * oi.unit_price) AS total_sales_amount,
  AVG(oi.quantity * oi.unit_price) AS avg_transaction_value,
  COUNT(DISTINCT o.customer_id) AS unique_customers,
  COUNT(DISTINCT oi.product_id) AS unique_products_sold,
  ROUND(SUM(oi.quantity * oi.unit_price) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS avg_order_value,
  ROUND(SUM(oi.quantity * oi.unit_price) / NULLIF(COUNT(DISTINCT o.customer_id), 0), 2) AS revenue_per_customer,
  CASE
    WHEN SUM(oi.quantity * oi.unit_price) >= 2000
    THEN 'High Performing'
    WHEN SUM(oi.quantity * oi.unit_price) >= 1000
    THEN 'Medium Performing'
    ELSE 'Low Performing'
  END AS warehouse_performance_tier
FROM vulcan_demo.warehouses AS w
LEFT JOIN vulcan_demo.regions AS r
  ON w.region_id = r.region_id
LEFT JOIN vulcan_demo.orders AS o
  ON w.warehouse_id = o.warehouse_id
LEFT JOIN vulcan_demo.order_items AS oi
  ON o.order_id = oi.order_id
LEFT JOIN vulcan_demo.dim_dates AS dd
  ON o.order_date = dd.dt
GROUP BY
  w.warehouse_id,
  w.name,
  r.region_name,
  o.order_date