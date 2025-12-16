MODEL (
  name vulcan_demo.seed_model,
  kind SEED (
    path '../seeds/seed_data.csv'
  ),
  columns (
    id INT,
    item_id INT,
    event_date DATE
  ),
  grains (
    id
  ),
  assertions (
    UNIQUE_COMBINATION_OF_COLUMNS(columns := (id, event_date)),
    NOT_NULL(columns := (id, item_id, event_date)),
    ACCEPTED_RANGE(column := id, min_v := 0),
    ACCEPTED_RANGE(column := item_id, min_v := 0),
    NUMBER_OF_ROWS(threshold := 0)
  )
)