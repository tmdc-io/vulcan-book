import typing as t
import pandas as pd
from datetime import datetime
from vulcan import ExecutionContext, model
from vulcan import ModelKindName

@model(
    "sales.daily_sales_py",
    columns={
        "order_date": "timestamp",
        "total_orders": "int",
        "total_revenue": "decimal(18,2)",
        "last_order_id": "string",
    },
    kind=dict(
        name=ModelKindName.FULL,
    ),
    grains=["order_date"],
    depends_on=["raw.raw_orders"],
    cron='@daily',
    description="Daily sales aggregated by order_date (total orders, revenue, last order id).",
)
def execute(
    context: ExecutionContext,
    start: datetime,
    end: datetime,
    execution_time: datetime,
    **kwargs: t.Any,
) -> pd.DataFrame:
    """FULL model - rebuilds entire daily_sales table each run"""

    query = f"""
    SELECT
      CAST(order_date AS TIMESTAMP) AS order_date,
      COUNT(order_id)::INTEGER AS total_orders,
      SUM(total_amount)::NUMERIC(18,2) AS total_revenue,
      MAX(order_id)::VARCHAR AS last_order_id
    FROM raw.raw_orders
    GROUP BY order_date
    ORDER BY order_date
    """

    return context.fetchdf(query)
