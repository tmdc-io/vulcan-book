MODEL (
  name vulcan_demo.incremental_by_unique_key,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key customer_id
  ),
  start '2025-01-01',
  cron '@daily',
  grains (
    customer_id
  ),
  assertions (
    UNIQUE_VALUES(columns := customer_id),
    NOT_NULL(columns := (customer_id, customer_name, email)),
    NOT_EMPTY_STRING(column := customer_name),
    NOT_EMPTY_STRING(column := email),
    ACCEPTED_VALUES(column := customer_segment, is_in := ('High Value', 'Medium Value', 'Low Value'))
  ),
  column_descriptions (
    customer_id = 'Customer ID',
    customer_name = 'Customer Name',
    email = 'Email Address',
    region_name = 'Region Name',
    total_orders = 'Total Orders',
    total_spent = 'Total Amount Spent',
    last_order_date = 'Last Order Date',
    customer_segment = 'Customer Segment'
  ),
  profiles (
    customer_id,
    customer_name,
    email,
    region_name,
    total_orders,
    total_spent,
    last_order_date,
    unique_products_purchased,
    customer_segment
  )
);

SELECT
  c.customer_id,
  c.name AS customer_name,
  c.email,
  r.region_name,
  COUNT(DISTINCT o.order_id) AS total_orders,
  COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_spent,
  MAX(o.order_date) AS last_order_date,
  COUNT(DISTINCT oi.product_id) AS unique_products_purchased,
  CASE
    WHEN COALESCE(SUM(oi.quantity * oi.unit_price), 0) >= 1000
    THEN 'High Value'
    WHEN COALESCE(SUM(oi.quantity * oi.unit_price), 0) >= 500
    THEN 'Medium Value'
    ELSE 'Low V.'
  END AS customer_segment
FROM vulcan_demo.customers AS c
LEFT JOIN vulcan_demo.regions AS r
  ON c.region_id = r.region_id
LEFT JOIN vulcan_demo.orders AS o
  ON c.customer_id = o.customer_id
LEFT JOIN vulcan_demo.order_items AS oi
  ON o.order_id = oi.order_id
LEFT JOIN vulcan_demo.dim_dates AS dd
  ON o.order_date = dd.dt
WHERE
  (
    o.order_date IS NULL OR o.order_date BETWEEN @start_date AND @end_date
  )
GROUP BY
  c.customer_id,
  c.name,
  c.email,
  r.region_name