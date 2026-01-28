MODEL (
  name vulcan_demo.full_model,
  kind FULL,
  start '2025-01-01',
  grains (
    customer_id
  ),
  assertions (
    UNIQUE_VALUES(columns := customer_id),
    NOT_NULL(columns := (customer_id, customer_name)),
    NOT_EMPTY_STRING(column := customer_name),
    ACCEPTED_RANGE(column := total_orders, min_v := 0),
    ACCEPTED_RANGE(column := total_spent, min_v := 0),
    ACCEPTED_RANGE(column := avg_order_value, min_v := 0)
  ),
  column_descriptions (
    customer_id = 'Customer ID',
    customer_name = 'Customer Name',
    total_orders = 'Total Number of Orders',
    total_spent = 'Total Amount Spent',
    avg_order_value = 'Average Order Value'
  ),
  profiles (customer_id, customer_name, email, total_orders, total_spent, avg_order_value)
);


SELECT
  c.customer_id,
  c.name AS customer_name,
  c.email,
  COUNT(DISTINCT o.order_id) AS total_orders,
  COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_spent,
  COALESCE(SUM(oi.quantity * oi.unit_price), 0) / NULLIF(COUNT(DISTINCT o.order_id), 0) AS avg_order_value
FROM vulcan_demo.customers AS c
LEFT JOIN vulcan_demo.orders AS o
  ON c.customer_id = o.customer_id
LEFT JOIN vulcan_demo.order_items AS oi
  ON o.order_id = oi.order_id
GROUP BY
  c.customer_id,
  c.name,
  c.email
ORDER BY
  total_spent DESC