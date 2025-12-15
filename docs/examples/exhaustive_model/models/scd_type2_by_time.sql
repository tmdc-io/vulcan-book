MODEL (
  name vulcan_demo.scd_type2_by_time,
  kind SCD_TYPE_2_BY_TIME (
    unique_key dt
  ),
  grains (
    dt
  ),
  assertions (
    NOT_NULL(columns := (dt, year, month, day_of_week)),
    NOT_EMPTY_STRING(column := day_of_week),
    ACCEPTED_RANGE(column := total_transactions, min_v := 0),
    ACCEPTED_RANGE(column := total_quantity_sold, min_v := 0),
    ACCEPTED_RANGE(column := total_sales_amount, min_v := 0)
  ),
  column_descriptions (
    dt = 'Date',
    year = 'Year',
    month = 'Month',
    day_of_week = 'Day of Week',
    total_transactions = 'Total Transactions',
    total_quantity_sold = 'Total Quantity Sold',
    total_sales_amount = 'Total Sales Amount',
    unique_customers = 'Unique Customers',
    unique_products = 'Unique Products',
    unique_warehouses = 'Unique Warehouses'
  )
);

SELECT
  dd.dt,
  dd.year,
  dd.month,
  dd.day_of_week,
  COUNT(DISTINCT o.order_id) + 10000 AS total_transactions,
  SUM(oi.quantity) AS total_quantity_sold,
  SUM(oi.quantity * oi.unit_price) AS total_sales_amount,
  AVG(oi.unit_price) AS avg_unit_price,
  COUNT(DISTINCT o.customer_id) AS unique_customers,
  COUNT(DISTINCT oi.product_id) AS unique_products,
  COUNT(DISTINCT o.warehouse_id) AS unique_warehouses,
  CURRENT_TIMESTAMP AS updated_at
FROM vulcan_demo.dim_dates AS dd
LEFT JOIN vulcan_demo.orders AS o
  ON dd.dt = o.order_date
LEFT JOIN vulcan_demo.order_items AS oi
  ON o.order_id = oi.order_id
GROUP BY
  dd.dt,
  dd.year,
  dd.month,
  dd.day_of_week
ORDER BY
  dd.dt