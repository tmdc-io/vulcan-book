MODEL (
  name vulcan_demo.stg_order_lines,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column (order_date)
  ),
  grains (order_id, item_id),
  start '2025-01-01'
);

WITH base AS (
  SELECT
    oi.order_id,
    oi.item_id,
    oi.product_id,
    oi.quantity::INT AS quantity,
    oi.unit_price::DECIMAL(10, 2) AS unit_price,
    CAST(oi.quantity * oi.unit_price AS DECIMAL(18, 2)) AS line_revenue,
    o.customer_id,
    o.order_date::TIMESTAMP AS order_date,
    o.warehouse_id,
    o.warehouse_id AS warehouse_id_filter
  FROM vulcan_demo.order_items AS oi
  LEFT JOIN vulcan_demo.orders AS o
    ON o.order_id = oi.order_id
  WHERE
    o.order_date BETWEEN @start_date AND @end_date
)
SELECT
  @GENERATE_SURROGATE_KEY(order_id, item_id) AS order_item_sk,
  order_id, /* everything from base EXCEPT product_id, warehouse_id */
  item_id,
  product_id,
  quantity,
  unit_price,
  line_revenue,
  customer_id,
  order_date::TIMESTAMP AS order_date,
  warehouse_id,
  warehouse_id_filter
FROM base