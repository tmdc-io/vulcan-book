/* Daily sales fact (date spine via dim_dates + metrics) */
MODEL (
  name vulcan_demo.fct_daily_sales,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column (sales_date)
  ),
  grains (sales_date, customer_sk),
  description 'Fact table at day grain with safe metrics and category bucketing.',
  profiles (
    sales_date,
    customer_sk,
    product_sk,
    region_id,
    region_name,
    category,
    category_bucket,
    units,
    revenue,
    avg_selling_price
  )
);

@WITH(TRUE) spine /* 1) Date spine from your dim_dates (safer on Spark than @DATE_SPINE in FROM) */ AS (
  SELECT
    dd.dt::DATE AS sales_date
  FROM vulcan_demo.dim_dates AS dd
  @WHERE(TRUE)
    dd.dt BETWEEN @start_date AND @end_date
), line_agg /* 2) Aggregate line items to the day/customer/product/warehouse grain */ AS (
  SELECT
    sol.order_date::TIMESTAMP AS sales_date,
    @GENERATE_SURROGATE_KEY(sol.customer_id, sc.email) AS customer_sk,
    sp.product_sk,
    SUM(sol.quantity)::INT AS units,
    SUM(sol.line_revenue)::DECIMAL(18, 2) AS revenue,
    @safe_ratio(SUM(sol.line_revenue), SUM(sol.quantity), 0.0) AS avg_selling_price
  FROM vulcan_demo.stg_order_lines AS sol
  @JOIN(TRUE) vulcan_demo.stg_customers AS sc
    ON sc.customer_id = sol.customer_id
  @JOIN(TRUE) vulcan_demo.stg_products AS sp
    ON sp.product_id = sol.item_id
  @WHERE(TRUE)
    sol.order_date BETWEEN @start_date AND @end_date
  @GROUP_BY(TRUE)
    sol.order_date,
    sol.customer_id,
    sc.email,
    sp.product_sk
), cat_rank /* 3) Top-N category ranking used by label_top_n_category() */ AS (
  SELECT
    sp.category,
    DENSE_RANK() OVER (ORDER BY SUM(sol.line_revenue) DESC) AS rnk
  FROM vulcan_demo.stg_order_lines AS sol
  @JOIN(TRUE) vulcan_demo.stg_products AS sp
    ON sp.product_id = sol.item_id
  @WHERE(TRUE)
    sol.order_date BETWEEN @start_date AND @end_date
  GROUP BY
    sp.category
), joined /* 4) Join dims for attributes */ AS (
  SELECT
    la.sales_date::TIMESTAMP AS sales_date,
    la.customer_sk,
    la.product_sk,
    dc.region_id,
    dc.region_name,
    sp.category,
    la.units,
    la.revenue,
    la.avg_selling_price,
    @label_top_n_category(sp.category, 5) AS category_bucket
  FROM line_agg AS la
  LEFT @JOIN(TRUE) vulcan_demo.dim_customer AS dc
    ON dc.customer_sk = la.customer_sk
  LEFT @JOIN(TRUE) vulcan_demo.stg_products AS sp
    ON sp.product_sk = la.product_sk
)
SELECT
  s.sales_date::TIMESTAMP,
  j.customer_sk::TEXT,
  j.product_sk::TEXT,
  j.region_id::INT,
  j.region_name::TEXT,
  j.category::TEXT,
  j.category_bucket::TEXT,
  j.units::INT,
  j.revenue::DECIMAL(18, 4),
  j.avg_selling_price::DOUBLE PRECISION
FROM spine AS s
LEFT @JOIN(TRUE) joined AS j
  ON j.sales_date = s.sales_date
@WHERE(TRUE)
  s.sales_date BETWEEN @start_date AND @end_date