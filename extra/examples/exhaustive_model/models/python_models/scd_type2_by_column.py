import typing as t
import pandas as pd
from datetime import datetime
from vulcan import ExecutionContext, model
from vulcan import ModelKindName

@model(
    "vulcan_demo.scd_type2_by_column_py",
    columns={
        "product_id": "int",
        "product_name": "string",
        "category": "string",
        "price": "decimal(10,2)"
    },
    kind=dict(
        name=ModelKindName.SCD_TYPE_2_BY_COLUMN,
        unique_key=["product_id"],
        columns=["product_name", "category", "price"],
    ),
    grains=["product_id"],
    depends_on=["vulcan_demo.products"],
)
def execute(
    context: ExecutionContext,
    start: datetime,
    end: datetime,
    execution_time: datetime,
    **kwargs: t.Any,
) -> pd.DataFrame:
    """SCD_TYPE_2_BY_COLUMN model - Slowly Changing Dimension Type 2 by column changes"""
    
    # Example of using blueprint_var() for variable-based dependencies
    schema_name = context.blueprint_var('schema_name', 'vulcan_demo')
    
    product_table = context.resolve_table("vulcan_demo.products")
    
    # Product dimension with SCD Type 2 logic
    query = f"""
    SELECT 
        product_id,
        name as product_name,
        category,
        price
    FROM vulcan_demo.products
    ORDER BY product_id
    """
    
    print(f"Using blueprint variable schema_name: {schema_name}")
    print(f"Product table: {product_table}")
    
    return context.fetchdf(query)


