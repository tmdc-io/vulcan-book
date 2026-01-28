import typing as t
import pandas as pd
from datetime import datetime
from vulcan import ExecutionContext, model
from vulcan import ModelKindName

@model(
    "vulcan_demo.full_model_py",
    columns={
        "product_id": "int",
        "product_name": "string",
        "category": "string",
        "total_sales": "decimal(10,2)",
    },
    kind=dict(
        name=ModelKindName.FULL,
    ),
    grains=["product_id"],
    depends_on=["vulcan_demo.products", "vulcan_demo.order_items", "vulcan_demo.orders"],
)
def execute(
    context: ExecutionContext,
    start: datetime,
    end: datetime,
    execution_time: datetime,
    **kwargs: t.Any,
) -> pd.DataFrame:
    """FULL model - rebuilds entire table each time with explicit dependencies"""
    
    # # Get table names using resolve_table
    # product_table = context.resolve_table("vulcan_demo.products")
    # order_items_table = context.resolve_table("vulcan_demo.order_items")
    # orders_table = context.resolve_table("vulcan_demo.orders")
    
    # Full product sales summary
    query = f"""
    SELECT 
        p.product_id,
        p.name AS product_name,
        p.category,
        COALESCE(SUM(oi.quantity * oi.unit_price), 0) as total_sales
    FROM vulcan_demo.products p
    LEFT JOIN vulcan_demo.order_items oi ON p.product_id = oi.product_id
    LEFT JOIN vulcan_demo.orders o ON oi.order_id = o.order_id
    GROUP BY p.product_id, p.name, p.category
    ORDER BY total_sales DESC
    """
    
    # print(f"Using product table: {product_table}")
    # print(f"Using order_items table: {order_items_table}")
    # print(f"Using orders table: {orders_table}")
    
    return context.fetchdf(query)


