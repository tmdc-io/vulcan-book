MODEL (
  name vulcan_demo.incremental_by_time_range,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column order_date,
    -- batch_size
    -- batch_concurrency
    -- lookback
    -- forward_only

  ),
  start '2025-01-01',
  grains (order_date, product_id),
  cron '*/5 * * * *',
  assertions (
    NOT_NULL(columns := (order_date, product_id, product_name, category)),
    NOT_EMPTY_STRING(column := (
      product_name
    )),
    ACCEPTED_RANGE(column := total_sales_amount, min_v := 0),
    ACCEPTED_RANGE(column := total_quantity, min_v := 0),
    ACCEPTED_RANGE(column := order_count, min_v := 0)
  ),
  column_descriptions (
    order_date = 'Order Date',
    product_id = 'Product ID',
    product_name = 'Product Name',
    category = 'Product Category',
    total_sales_amount = 'Total Sales Amount',
    total_quantity = 'Total Quantity Sold',
    order_count = 'Number of Orders'
  ),
  signals (
    DATA_AVAILABLE_FOR_TODAY()
  ),
  profiles (
    order_date,
    product_id,
    product_name,
    category,
    total_sales_amount,
    total_quantity,
    order_count
  )
);

SELECT
  o.order_date,
  p.product_id,
  p.name AS product_name,
  p.category,
  COUNT(DISTINCT o.order_id) AS order_count,
  SUM(oi.quantity) AS total_quantity,
  SUM(oi.quantity * oi.unit_price) AS total_sales_amount,
  AVG(oi.unit_price) AS avg_unit_price
FROM vulcan_demo.orders AS o
JOIN vulcan_demo.order_items AS oi
  ON o.order_id = oi.order_id
JOIN vulcan_demo.products AS p
  ON oi.product_id = p.product_id
WHERE
  o.order_date BETWEEN @start_ds AND @end_ds
GROUP BY
  o.order_date,
  p.product_id,
  p.name,
  p.category
ORDER BY
  o.order_date,
  total_sales_amount DESC