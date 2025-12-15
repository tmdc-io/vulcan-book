import typing as t
import pandas as pd
from datetime import datetime
from vulcan import ExecutionContext, model
from vulcan import ModelKindName

@model(
    "vulcan_demo.partition_py",
    columns={
        "warehouse_id": "int",
        "order_date": "date",
        "daily_revenue": "decimal(10,2)",
    },
    partitioned_by=["warehouse_id"],
    kind=dict(
        name=ModelKindName.INCREMENTAL_BY_PARTITION,
    ),
    grains=["warehouse_id", "order_date"],
    depends_on=["vulcan_demo.orders", "vulcan_demo.order_items"],
)
def execute(
    context: ExecutionContext,
    start: datetime,
    end: datetime,
    execution_time: datetime,
    **kwargs: t.Any,
) -> pd.DataFrame:
    """INCREMENTAL_BY_PARTITION model - processes by partition with dynamic dependencies"""
    
    # Dynamic dependency - this will be automatically captured
        # orders_table = context.resolve_table("vulcan_demo.orders")
        # order_items_table = context.resolve_table("vulcan_demo.order_items")
    
    # Warehouse daily revenue by partition
    query = f"""
    SELECT 
        o.warehouse_id,
        o.order_date,
        SUM(oi.quantity * oi.unit_price) as daily_revenue
    FROM vulcan_demo.orders o
    JOIN vulcan_demo.order_items oi ON o.order_id = oi.order_id
    GROUP BY o.warehouse_id, o.order_date
    ORDER BY o.warehouse_id, o.order_date
    """
    
    # print(f"Dynamic dependency - Orders table: {orders_table}")
    # print(f"Dynamic dependency - Order items table: {order_items_table}")
    print(f"Query: {query}")
    
    # Execute query
    df = context.fetchdf(query)
    print(df)
    
    # Print DataFrame for debugging
    print(f"DataFrame shape: {df.shape}")
    print(f"DataFrame contents:\n{df}")
    
    # Return the DataFrame (even if empty) - let SQLMesh handle empty results
    return df


