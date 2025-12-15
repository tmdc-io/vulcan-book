MODEL (
  name sqlmesh_example.incremental_model,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date
  ),
  start '2020-01-01',
  cron '@daily',
  grains (
    id
  ),
  assertions (
    UNIQUE_COMBINATION_OF_COLUMNS(columns := (id, event_date)),
    NOT_NULL(columns := (id, item_id, event_date)),
    ACCEPTED_RANGE(column := id, min_v := 0),
    ACCEPTED_RANGE(column := item_id, min_v := 0),
    assert_positive_order_ids()
  ),
  profiles (*)
);

SELECT
  id,
  item_id,
  event_date
FROM vulcan_demo.seed_model
WHERE
  event_date BETWEEN @start_date AND @end_date