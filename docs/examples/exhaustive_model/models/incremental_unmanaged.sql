MODEL (
  name vulcan_demo.incremental_unmanaged,
  kind INCREMENTAL_UNMANAGED,
  cron '@daily',
  start '2025-01-01',
  grains (
    shipment_id
  ),
  assertions (
    UNIQUE_VALUES(columns := shipment_id),
    NOT_NULL(columns := (shipment_id, order_id, shipped_date, carrier, customer_id)),
    NOT_EMPTY_STRING(column := carrier),
    NOT_EMPTY_STRING(column := customer_name),
    ACCEPTED_RANGE(column := days_to_ship, min_v := 0, max_v := 365),
    ACCEPTED_RANGE(column := total_order_value, min_v := 0)
  ),
  column_descriptions (
    shipment_id = 'Shipment ID',
    order_id = 'Order ID',
    shipped_date = 'Shipment Date',
    carrier = 'Carrier Name',
    customer_id = 'Customer ID',
    customer_name = 'Customer Name',
    order_date = 'Original Order Date',
    days_to_ship = 'Days from Order to Shipment',
    total_order_value = 'Total Order Value',
    shipment_event_timestamp = 'Event Timestamp'
  )
);

/* Append-only shipment event log */
/* This model demonstrates INCREMENTAL_UNMANAGED: each shipment event */
/* is appended to the table without SQLMesh managing updates or deletes. */
/* Ideal for audit trails, event logs, and append-only data patterns. */
SELECT
  s.shipment_id,
  s.order_id,
  s.shipped_date,
  s.carrier,
  o.customer_id,
  c.name AS customer_name,
  o.order_date,
  (
    s.shipped_date - o.order_date::DATE
  )::INT AS days_to_ship,
  COALESCE(
    (
      SELECT
        SUM(oi.quantity * oi.unit_price)
      FROM vulcan_demo.order_items AS oi
      WHERE
        oi.order_id = o.order_id
    ),
    0
  ) AS total_order_value,
  CURRENT_TIMESTAMP AS shipment_event_timestam
FROM vulcan_demo.shipments AS s
JOIN vulcan_demo.orders AS o
  ON s.order_id = o.order_id
JOIN vulcan_demo.customers AS c
  ON o.customer_id = c.customer_id
ORDER BY
  s.shipped_date DESC,
  s.shipment_id