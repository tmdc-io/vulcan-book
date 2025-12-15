MODEL (
  name vulcan_demo.partition,
  kind INCREMENTAL_BY_PARTITION,
  partitioned_by ARRAY[warehouse_id, category],
  grains (
    partitioned_analysis_key
  ),
  assertions (
    UNIQUE_VALUES(columns := partitioned_analysis_key),
    NOT_NULL(
      columns := (warehouse_id, warehouse_name, category, order_date, partitioned_analysis_key)
    ),
    NOT_EMPTY_STRING(column := (
      warehouse_name
    )),
    ACCEPTED_RANGE(column := total_sales_amount, min_v := 0),
    ACCEPTED_RANGE(column := total_transactions, min_v := 0),
    ACCEPTED_RANGE(column := unique_customers, min_v := 0),
    ACCEPTED_RANGE(column := avg_order_value, min_v := 0)
  ),
  column_descriptions (
    warehouse_id = 'Warehouse ID',
    warehouse_name = 'Warehouse Name',
    category = 'Product Category',
    order_date = 'Order Date',
    total_sales_amount = 'Total Sales Amount',
    total_transactions = 'Total Transactions',
    unique_customers = 'Unique Customers',
    avg_order_value = 'Average Order Value'
  ),
  profiles (
    warehouse_id,
    warehouse_name,
    category,
    order_date,
    partitioned_analysis_key,
    total_transactions,
    total_quantity_sold,
    total_sales_amount,
    avg_transaction_value,
    unique_customers,
    unique_products,
    avg_order_value,
    revenue_per_customer,
    category_rank_in_warehouse
  )
);

SELECT
  w.warehouse_id,
  w.name AS warehouse_name,
  p.category,
  o.order_date,
  CONCAT(w.warehouse_id::TEXT, '_', p.category, '_', o.order_date::TEXT) AS partitioned_analysis_key,
  COUNT(DISTINCT o.order_id) AS total_transactions,
  SUM(oi.quantity) AS total_quantity_sold,
  SUM(oi.quantity * oi.unit_price) AS total_sales_amount,
  AVG(oi.quantity * oi.unit_price) AS avg_transaction_value,
  COUNT(DISTINCT o.customer_id) AS unique_customers,
  COUNT(DISTINCT oi.product_id) AS unique_products,
  ROUND(SUM(oi.quantity * oi.unit_price) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS avg_order_value,
  ROUND(SUM(oi.quantity * oi.unit_price) / NULLIF(COUNT(DISTINCT o.customer_id), 0), 2) AS revenue_per_customer,
  RANK() OVER (
    PARTITION BY w.warehouse_id, o.order_date
    ORDER BY SUM(oi.quantity * oi.unit_price) DESC
  ) AS category_rank_in_warehouse
FROM vulcan_demo.orders AS o
JOIN vulcan_demo.order_items AS oi
  ON o.order_id = oi.order_id
JOIN vulcan_demo.products AS p
  ON oi.product_id = p.product_id
JOIN vulcan_demo.warehouses AS w
  ON o.warehouse_id = w.warehouse_id
GROUP BY
  w.warehouse_id,
  w.name,
  p.category,
  o.order_date
ORDER BY
  w.warehouse_id,
  o.order_date,
  total_sales_amount DESC