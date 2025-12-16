from datetime import datetime, timedelta
from vulcan import signal, DatetimeRanges, ExecutionContext

@signal()
def data_available_for_today(batch: DatetimeRanges, context: ExecutionContext) -> bool:
    # print(dict(batch))
    overall_start = min(s for s, _ in batch)
    overall_end = max(e for _, e in batch)
    # print(overall_start, overall_end)

    today = datetime.utcnow().date()
    query = f"""
        SELECT COUNT(*) AS cnt
        FROM vulcan_demo.orders
        WHERE order_date::timestamp BETWEEN '{overall_start}' AND '{overall_end}'
    """
    df = context.engine_adapter.fetchdf(query)
    count = int(df.iloc[0]['cnt'])
    if count > 0:
        return True
    return False
