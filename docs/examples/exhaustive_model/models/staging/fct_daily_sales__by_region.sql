MODEL (
  name vulcan_demo.fct_daily_sales__@{region},
  kind VIEW,
  blueprints (
    (
      region := 'north'
    ),
    (
      region := 'south'
    ),
    (
      region := 'east'
    ),
    (
      region := 'west'
    )
  ),
  grains region_id
);

SELECT
  *
FROM vulcan_demo.fct_daily_sales
@WHERE(TRUE)
  LOWER(region_name) = LOWER(@region) /* In SQL (literal) context, use @region (no braces) since the blueprint value is quoted above. */