import typing as t
import pandas as pd
from datetime import datetime
from vulcan import ExecutionContext, model
from vulcan import ModelKindName

@model(
    "vulcan_demo.scd_type2_by_time_py",
    columns={
        "customer_id": "int",
        "customer_name": "string",
        "email": "string",
        "region_name": "string"
    },
    kind=dict(
        name=ModelKindName.SCD_TYPE_2_BY_TIME,
        unique_key=["customer_id"],
    ),
    grains=["customer_id"],
    depends_on=["vulcan_demo.customers", "vulcan_demo.regions"],
)
def execute(
    context: ExecutionContext,
    start: datetime,
    end: datetime,
    execution_time: datetime,
    **kwargs: t.Any,
) -> pd.DataFrame:
    """SCD_TYPE_2_BY_TIME model - Slowly Changing Dimension Type 2 by time"""
    
    # Customer dimension with SCD Type 2 logic
    query = """
    SELECT 
        c.customer_id,
        c.name as customer_name,
        c.email,
        r.region_name,
        CURRENT_TIMESTAMP as updated_at
    FROM vulcan_demo.customers c
    LEFT JOIN vulcan_demo.regions r ON c.region_id = r.region_id
    ORDER BY c.customer_id
    """
    
    return context.fetchdf(query)


