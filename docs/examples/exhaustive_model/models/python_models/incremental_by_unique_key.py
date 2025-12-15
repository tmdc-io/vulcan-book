import typing as t
import pandas as pd
from datetime import datetime
from vulcan import ExecutionContext, model
from vulcan import ModelKindName

@model(
    "vulcan_demo.incremental_by_unique_key_py",
    columns={
        "customer_id": "int",
        "total_spent": "decimal(10,2)",
        "last_order_date": "date",
    },
    kind=dict(
        name=ModelKindName.INCREMENTAL_BY_UNIQUE_KEY,
        unique_key=["customer_id"],
    ),
    grains=["customer_id"],
    depends_on=["vulcan_demo.customers", "vulcan_demo.orders", "vulcan_demo.order_items"],
)
def execute(
    context: ExecutionContext,
    start: datetime,
    end: datetime,
    execution_time: datetime,
    **kwargs: t.Any,
) -> pd.DataFrame:
    """INCREMENTAL_BY_UNIQUE_KEY model - processes by unique key"""
    
    # Customer spending summary
    query = """
    SELECT 
        c.customer_id,
        SUM(oi.quantity * oi.unit_price) as total_spent,
        MAX(o.order_date) as last_order_date
    FROM vulcan_demo.customers c
    LEFT JOIN vulcan_demo.orders o ON c.customer_id = o.customer_id
    LEFT JOIN vulcan_demo.order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_id
    ORDER BY total_spent DESC
    """
    
    return context.fetchdf(query)


