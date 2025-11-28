# Chapter 2D: Model Optimization

> **Optimize model performance and warehouse costs** - Performance tuning, warehouse-specific optimization, query optimization, and best practices for production models.

---

## Prerequisites

Before reading this chapter, you should be familiar with:

- [Chapter 2: Models](index.md) - Foundation concepts
- [Chapter 2A: Model Properties](model-properties.md) - Property reference
- Basic understanding of your data warehouse (Snowflake, BigQuery, Databricks, etc.)
- SQL query optimization concepts

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Performance Fundamentals](#2-performance-fundamentals)
3. [Model Kinds Optimization](#3-model-kinds-optimization)
4. [Query Optimization](#4-query-optimization)
5. [Warehouse-Specific Optimization](#5-warehouse-specific-optimization)
6. [Advanced Properties Optimization](#6-advanced-properties-optimization)
7. [Cost Optimization](#7-cost-optimization)
8. [Troubleshooting Performance](#8-troubleshooting-performance)
9. [Best Practices](#9-best-practices)
10. [Summary and Next Steps](#10-summary-and-next-steps)

---

## 1. Introduction

Model optimization is critical for:
- **Performance**: Faster execution times
- **Cost**: Lower warehouse compute costs
- **Reliability**: Avoiding timeouts and failures
- **Scalability**: Handling growing data volumes

**This chapter covers:**
- Choosing optimal model kinds
- Query optimization strategies
- Warehouse-specific tuning
- Cost optimization techniques
- Performance troubleshooting

**For basics, see [Chapter 2: Models](index.md)**

[↑ Back to Top](#chapter-2d-model-optimization)

---

## 2. Performance Fundamentals

### 2.1 Understanding Performance Bottlenecks

**Common bottlenecks:**

1. **Full table scans** - Scanning entire tables instead of partitions
2. **Large backfills** - Processing years of data in one job
3. **Inefficient joins** - Cartesian products, missing indexes
4. **Over-aggregation** - Computing unnecessary aggregations
5. **Resource contention** - Too many concurrent queries

**Performance equation:**

```
Total Execution Time = 
  Query Execution Time + 
  Data Transfer Time + 
  Warehouse Overhead
```

**Optimization targets:**
- Reduce data scanned (partitioning, filtering)
- Reduce computation (aggregation, joins)
- Reduce concurrency conflicts (batching, scheduling)

### 2.2 Incremental vs Full Refresh

**The biggest performance win: Use incremental models**

```sql
-- ❌ FULL: Rebuilds entire table every run
MODEL (
  name analytics.events,
  kind FULL
);
-- Execution: 2 hours, scans 100M rows daily

-- ✅ INCREMENTAL: Only processes new data
MODEL (
  name analytics.events,
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_date)
);
-- Execution: 5 minutes, scans 1M rows daily (today's data only)
```

**Performance improvement:**
- **10-100x faster** execution
- **10-100x lower** compute costs
- **Scalable** as data grows

**When incremental isn't possible:**
- Small lookup tables (< 1M rows) - FULL is fine
- Non-temporal data - Use FULL or INCREMENTAL_BY_UNIQUE_KEY
- Frequently changing logic - Consider VIEW

### 2.3 Query Execution Patterns

**Pattern 1: Filter Early**

```sql
-- ❌ Bad: Filter after join
SELECT *
FROM large_table l
JOIN huge_table h ON l.id = h.id
WHERE l.event_date = '2024-01-15';

-- ✅ Good: Filter before join
SELECT *
FROM (
  SELECT * FROM large_table 
  WHERE event_date = '2024-01-15'
) l
JOIN huge_table h ON l.id = h.id;
```

**Pattern 2: Use Partition Pruning**

```sql
-- ✅ Partitioned table with filter
MODEL (
  name analytics.events,
  partitioned_by event_date
);

SELECT * FROM analytics.events
WHERE event_date BETWEEN @start_ds AND @end_ds;
-- Only scans partitions for date range
```

**Pattern 3: Pre-aggregate When Possible**

```sql
-- ❌ Bad: Expose raw events (billions of rows)
MODEL (name analytics.raw_events);
SELECT * FROM raw.events;

-- ✅ Good: Pre-aggregate (millions of rows)
MODEL (name analytics.daily_event_summary);
SELECT
  event_date,
  customer_id,
  event_type,
  COUNT(*) as event_count,
  SUM(value) as total_value
FROM raw.events
GROUP BY event_date, customer_id, event_type;
```

### 2.4 Batch Processing

**Use `batch_size` for large backfills:**

```sql
MODEL (
  name analytics.hourly_events,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date,
    batch_size 24  -- Process 24 hours per batch
  ),
  cron '@hourly'
);
```

**Why batch?**

- **Without batching**: 72 hours = 1 job (may timeout)
- **With batching**: 72 hours ÷ 24 = 3 jobs (reliable)

**Batch size guidelines:**

| Model Frequency | Recommended Batch Size |
|----------------|------------------------|
| Hourly | 12-48 hours |
| Daily | 7-30 days |
| Weekly | 4-12 weeks |

**Start conservative, increase if stable:**

```sql
-- Start small
batch_size 7  -- 7 days per batch

-- Increase if stable
batch_size 30  -- 30 days per batch
```

### 2.5 Concurrency Control

**Use `batch_concurrency` to limit parallel execution:**

```sql
MODEL (
  name analytics.events,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date,
    batch_size 24,
    batch_concurrency 3  -- Max 3 batches in parallel
  )
);
```

**Why limit concurrency?**

- **Warehouse limits**: Most warehouses have connection limits
- **Resource contention**: Too many queries compete for resources
- **Cost control**: Parallel queries multiply costs

**Concurrency guidelines:**

- **Snowflake**: 5-10 concurrent queries per warehouse
- **BigQuery**: 100 concurrent queries (but use slots wisely)
- **Databricks**: Depends on cluster size

**Monitor and adjust:**

```bash
# Check warehouse utilization
vulcan info

# Adjust if you see:
# - Query timeouts → Reduce batch_concurrency
# - Underutilized warehouse → Increase batch_concurrency
```

[↑ Back to Top](#chapter-2d-model-optimization)

---

## 3. Model Kinds Optimization

### 3.1 Choosing the Right Model Kind

**Decision tree:**

```
Is data temporal (time-based)?
│
├─ YES → Use INCREMENTAL_BY_TIME_RANGE
│  │
│  └─ Need late-arriving data handling?
│     └─ YES → Add lookback
│
├─ NO → Is data append-only?
│  │
│  ├─ YES → Use INCREMENTAL_BY_UNIQUE_KEY
│  │
│  └─ NO → Need historical tracking?
│     │
│     ├─ YES → Use SCD_TYPE_2
│     │
│     └─ NO → Use FULL
│
└─ Is table small (< 1M rows)?
   └─ YES → FULL is fine (simple, fast)
```

### 3.2 INCREMENTAL_BY_TIME_RANGE Optimization

**Most common model kind - optimize carefully:**

#### Time Column Selection

**Choose the right time column:**

```sql
-- ✅ Good: UTC timestamp column
MODEL (
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_timestamp_utc
  )
);

-- ❌ Bad: Local time (timezone issues)
MODEL (
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_timestamp_local  -- Avoid timezone confusion
  )
);
```

**Best practices:**
- Use UTC timestamps
- Use DATE columns for daily models
- Index the time column

#### Lookback Optimization

**Balance late data vs performance:**

```sql
-- ❌ Too aggressive: Reprocesses too much
lookback 30  -- Reprocesses last 30 days every run

-- ✅ Balanced: Handles late data efficiently
lookback 3  -- Reprocesses last 3 days

-- ❌ Too conservative: Misses late data
lookback 0  -- No late data handling
```

**Lookback guidelines:**

| Data Latency | Recommended Lookback |
|--------------|---------------------|
| Real-time (< 1 hour) | 0-1 intervals |
| Daily batch | 1-3 days |
| Weekly batch | 3-7 days |
| High latency | 7-30 days |

**Performance impact:**

```
Without lookback: Processes 1 interval
With lookback 7: Processes 8 intervals (7 + current)
Cost: ~8x more expensive
```

**Monitor late-arriving data:**

```sql
-- Check for late arrivals
SELECT 
  event_date,
  COUNT(*) as late_arrivals
FROM raw.events
WHERE event_date < CURRENT_DATE - INTERVAL '7 days'
  AND created_at > CURRENT_DATE - INTERVAL '1 day'
GROUP BY event_date
ORDER BY event_date DESC;
```

#### WHERE Clause Optimization

**Always filter by time range:**

```sql
-- ✅ Good: Filters in query
SELECT *
FROM raw.events
WHERE event_date BETWEEN @start_ds AND @end_ds;

-- ❌ Bad: No filter (scans entire table)
SELECT * FROM raw.events;
```

**Use partition-aware filters:**

```sql
-- ✅ Good: Filter on partition column
SELECT *
FROM raw.events
WHERE event_date BETWEEN @start_ds AND @end_ds
  AND event_type = 'purchase';  -- Additional filter

-- ❌ Bad: Filter on non-partition column first
SELECT *
FROM raw.events
WHERE event_type = 'purchase'  -- Can't use partition pruning
  AND event_date BETWEEN @start_ds AND @end_ds;
```

### 3.3 INCREMENTAL_BY_UNIQUE_KEY Optimization

**Optimize for append-only data:**

```sql
MODEL (
  name analytics.user_sessions,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key session_id
  )
);
```

**Key considerations:**

- **Unique key selection**: Choose stable, unique identifier
- **No lookback**: This kind doesn't support lookback
- **MERGE performance**: Ensure unique key is indexed

**Optimize MERGE operations:**

```sql
MODEL (
  name analytics.orders,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key order_id,
    when_matched 'UPDATE',  -- Customize MERGE behavior
    merge_filter 'source.status != target.status'  -- Only update if changed
  )
);
```

### 3.4 SCD_TYPE_2 Optimization

**Optimize for historical tracking:**

```sql
MODEL (
  name dim.customers,
  kind SCD_TYPE_2_BY_TIME (
    time_column updated_at,
    unique_key customer_id
  )
);
```

**Performance tips:**

- **Use SCD_TYPE_2_BY_TIME** (recommended) - More efficient than BY_COLUMN
- **Index unique key** - Faster lookups
- **Limit columns tracked** - Only track columns that change

**Avoid tracking too many columns:**

```sql
-- ❌ Bad: Tracks all columns (expensive)
kind SCD_TYPE_2_BY_COLUMN (
  columns (name, email, address, phone, preferences, ...)
)

-- ✅ Good: Tracks only important columns
kind SCD_TYPE_2_BY_TIME (
  time_column updated_at  -- Simpler, more efficient
)
```

### 3.5 VIEW vs TABLE Tradeoffs

**VIEW models:**

```sql
MODEL (
  name analytics.realtime_metrics,
  kind VIEW
);
```

**Use VIEW when:**
- ✅ Data changes frequently
- ✅ Always need latest data
- ✅ Upstream models are fast
- ✅ No performance issues

**Use TABLE (FULL/INCREMENTAL) when:**
- ✅ Downstream models need consistent snapshots
- ✅ Upstream models are slow
- ✅ Need to cache expensive computations
- ✅ Need to control refresh timing

**Performance comparison:**

| Aspect | VIEW | TABLE |
|--------|------|-------|
| Execution | Every query | Once per refresh |
| Consistency | Always latest | Snapshot at refresh time |
| Performance | Depends on upstream | Cached |
| Cost | Per query | Per refresh |

### 3.6 FULL Model Optimization

**Optimize full refresh models:**

```sql
MODEL (
  name dim.products,
  kind FULL
);
```

**When FULL is appropriate:**

- ✅ Small tables (< 1M rows)
- ✅ Non-temporal data
- ✅ Simple transformations
- ✅ Infrequent changes

**Optimization strategies:**

1. **Add indexes** (if supported):
```sql
-- Postgres, MySQL
CREATE INDEX idx_product_id ON dim.products(product_id);
```

2. **Use materialized views** (if supported):
```sql
-- BigQuery
CREATE MATERIALIZED VIEW dim.products_mv AS
SELECT * FROM raw.products;
```

3. **Schedule appropriately**:
```sql
MODEL (
  name dim.products,
  kind FULL,
  cron '@weekly'  -- Refresh weekly, not daily
);
```

[↑ Back to Top](#chapter-2d-model-optimization)

---

## 4. Query Optimization

### 4.1 SQL Query Best Practices

#### Select Only Needed Columns

```sql
-- ❌ Bad: SELECT *
SELECT * FROM large_table;

-- ✅ Good: Select specific columns
SELECT 
  customer_id,
  order_date,
  amount
FROM large_table;
```

**Benefits:**
- Less data transferred
- Faster execution
- Lower costs

#### Use Efficient Joins

```sql
-- ❌ Bad: Cartesian product risk
SELECT *
FROM table1 t1
JOIN table2 t2;  -- Missing join condition

-- ✅ Good: Explicit join conditions
SELECT *
FROM table1 t1
JOIN table2 t2 ON t1.id = t2.id;
```

**Join order matters:**

```sql
-- ✅ Good: Filter before join
SELECT *
FROM (
  SELECT * FROM large_table 
  WHERE event_date = '2024-01-15'
) filtered
JOIN small_table s ON filtered.id = s.id;

-- ❌ Bad: Join before filter
SELECT *
FROM large_table l
JOIN small_table s ON l.id = s.id
WHERE l.event_date = '2024-01-15';
```

#### Avoid Unnecessary Aggregations

```sql
-- ❌ Bad: Aggregating then filtering
SELECT customer_id, SUM(amount)
FROM orders
GROUP BY customer_id
HAVING SUM(amount) > 1000;

-- ✅ Good: Filter before aggregating
SELECT customer_id, SUM(amount)
FROM orders
WHERE amount > 0  -- Filter early
GROUP BY customer_id
HAVING SUM(amount) > 1000;
```

#### Use Window Functions Efficiently

```sql
-- ✅ Good: Efficient window function
SELECT 
  customer_id,
  order_date,
  amount,
  SUM(amount) OVER (
    PARTITION BY customer_id 
    ORDER BY order_date 
    ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
  ) AS rolling_30day_total
FROM orders;

-- ❌ Bad: Self-join for rolling calculation
SELECT 
  o1.customer_id,
  o1.order_date,
  o1.amount,
  SUM(o2.amount) AS rolling_30day_total
FROM orders o1
JOIN orders o2 
  ON o1.customer_id = o2.customer_id
  AND o2.order_date BETWEEN o1.order_date - INTERVAL '30 days' AND o1.order_date
GROUP BY o1.customer_id, o1.order_date, o1.amount;
```

### 4.2 SQLGlot Query Optimizer

**Vulcan uses SQLGlot to optimize queries automatically:**

```sql
MODEL (
  name analytics.customers,
  optimize_query TRUE  -- Default: enabled
);
```

**What the optimizer does:**

1. **Qualifies column names** - Adds table prefixes
2. **Simplifies expressions** - Reduces complexity
3. **Inlines CTEs** - Expands common table expressions
4. **Optimizes subqueries** - Converts to joins when possible
5. **Removes redundant operations** - Eliminates unnecessary steps

**Example optimization:**

```sql
-- Before optimization
WITH customer_totals AS (
  SELECT customer_id, SUM(amount) as total
  FROM orders
  GROUP BY customer_id
)
SELECT * FROM customer_totals WHERE total > 1000;

-- After optimization (inlined)
SELECT customer_id, SUM(amount) as total
FROM orders
GROUP BY customer_id
HAVING SUM(amount) > 1000;
```

**When to disable optimizer:**

```sql
MODEL (
  name analytics.complex_query,
  optimize_query FALSE  -- Disable if causes issues
);
```

**Disable when:**
- Query exceeds database text limits after optimization
- Optimizer produces incorrect results (rare SQLGlot bugs)
- Complex dynamic SQL with macros
- You need to preserve exact query structure

**⚠️ Warning:** Disabling prevents column-level lineage tracking!

### 4.3 CTE Optimization

**Use CTEs for readability, but be aware of performance:**

```sql
-- ✅ Good: CTEs improve readability
WITH 
  filtered_orders AS (
    SELECT * FROM orders WHERE order_date >= '2024-01-01'
  ),
  customer_totals AS (
    SELECT customer_id, SUM(amount) as total
    FROM filtered_orders
    GROUP BY customer_id
  )
SELECT * FROM customer_totals WHERE total > 1000;
```

**CTE performance considerations:**

- **Materialized CTEs** (some warehouses): CTEs are computed once
- **Inlined CTEs** (most warehouses): CTEs are expanded inline
- **Multiple references**: May recompute CTE multiple times

**Optimize multiple CTE references:**

```sql
-- ❌ Bad: CTE referenced multiple times (may recompute)
WITH expensive_cte AS (
  SELECT * FROM huge_table WHERE complex_condition
)
SELECT * FROM expensive_cte
UNION ALL
SELECT * FROM expensive_cte;

-- ✅ Good: Materialize if needed (warehouse-specific)
-- Or: Use temporary table for very expensive CTEs
```

### 4.4 Subquery Optimization

**Convert correlated subqueries to joins:**

```sql
-- ❌ Bad: Correlated subquery
SELECT 
  customer_id,
  (SELECT MAX(order_date) 
   FROM orders o2 
   WHERE o2.customer_id = o1.customer_id) AS last_order_date
FROM customers o1;

-- ✅ Good: Join with aggregation
SELECT 
  c.customer_id,
  MAX(o.order_date) AS last_order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id;
```

**Use EXISTS instead of IN for large lists:**

```sql
-- ❌ Bad: IN with large list
SELECT * FROM orders
WHERE customer_id IN (
  SELECT customer_id FROM customers WHERE status = 'active'
  -- Returns 1M customer IDs
);

-- ✅ Good: EXISTS (often more efficient)
SELECT * FROM orders o
WHERE EXISTS (
  SELECT 1 FROM customers c
  WHERE c.customer_id = o.customer_id
    AND c.status = 'active'
);
```

### 4.5 Index Usage

**Add indexes on frequently filtered columns:**

```sql
-- Post-query optimization (via post_statements)
MODEL (
  name analytics.orders,
  post_statements [
    'CREATE INDEX idx_customer_id ON analytics.orders(customer_id)',
    'CREATE INDEX idx_order_date ON analytics.orders(order_date)'
  ]
);
```

**Index guidelines:**

- **Filter columns**: Index columns in WHERE clauses
- **Join columns**: Index foreign keys
- **Time columns**: Index time columns for incremental models
- **Composite indexes**: For multi-column filters

**Warehouse-specific:**

- **Snowflake**: Automatic clustering (no manual indexes)
- **BigQuery**: Automatic indexing (no manual indexes)
- **Postgres/MySQL**: Manual indexes required
- **Databricks**: Z-ordering instead of indexes

[↑ Back to Top](#chapter-2d-model-optimization)

---

## 5. Warehouse-Specific Optimization

### 5.1 Snowflake Optimization

#### Clustering Keys

**Snowflake uses automatic clustering, but you can optimize:**

```sql
MODEL (
  name analytics.events,
  clustered_by (customer_id, event_date)  -- Optimize for common queries
);
```

**Clustering guidelines:**

- **High cardinality columns**: Customer IDs, user IDs
- **Filter columns**: Columns frequently used in WHERE clauses
- **Join columns**: Foreign keys
- **Limit to 3-4 columns**: More columns = diminishing returns

**Monitor clustering:**

```sql
-- Check clustering effectiveness
SELECT SYSTEM$CLUSTERING_INFORMATION('analytics.events', '(customer_id, event_date)');
```

#### Warehouse Selection

**Use appropriate warehouse size:**

```sql
MODEL (
  name analytics.large_processing,
  physical_properties (
    warehouse = 'LARGE_WH'  -- Use larger warehouse for heavy queries
  )
);
```

**Warehouse sizing:**

- **X-Small**: Development, small queries
- **Small**: Most production models
- **Medium**: Large aggregations, complex joins
- **Large+**: Very large backfills, heavy processing

#### Transient Tables

**Use transient tables for cost savings:**

```sql
MODEL (
  name analytics.temp_metrics,
  physical_properties (
    creatable_type = TRANSIENT,  -- Lower cost, no fail-safe
    data_retention_time_in_days = 0  -- No Time Travel
  )
);
```

**When to use transient:**

- ✅ Intermediate/temporary models
- ✅ Models rebuilt frequently
- ✅ No need for Time Travel
- ❌ Production fact tables (use permanent)

#### Query Tagging

**Tag queries for monitoring:**

```sql
MODEL (
  name analytics.customer_metrics,
  session_properties (
    query_tag = 'analytics_pipeline_customer'  -- Track in query history
  )
);
```

**Benefits:**

- Track query costs by pipeline
- Monitor performance trends
- Debug slow queries

### 5.2 BigQuery Optimization

#### Partitioning

**Partition by date for time-series data:**

```sql
MODEL (
  name analytics.events,
  partitioned_by event_date,  -- Partition by DATE column
  physical_properties (
    partition_expiration_days = 90,  -- Auto-delete old partitions
    require_partition_filter = TRUE  -- Force partition filtering
  )
);
```

**Partition types:**

- **DATE**: Daily partitions (most common)
- **TIMESTAMP**: Hourly partitions (for high-frequency data)
- **INTEGER**: Range partitions (for numeric ranges)

**Partition expiration:**

```sql
physical_properties (
  partition_expiration_days = 365  -- Auto-delete partitions older than 1 year
)
```

#### Clustering

**Cluster by high-cardinality columns:**

```sql
MODEL (
  name analytics.orders,
  partitioned_by order_date,
  clustered_by (customer_id, product_id)  -- Optimize for common filters
);
```

**Clustering guidelines:**

- **Up to 4 columns**: More columns = diminishing returns
- **High cardinality**: Customer IDs, product IDs
- **Filter columns**: Columns in WHERE clauses
- **Join columns**: Foreign keys

**Performance impact:**

- **10-100x faster** queries with partition + cluster filters
- **Lower costs** (scan less data)

#### Require Partition Filter

**Force partition filtering:**

```sql
MODEL (
  name analytics.events,
  partitioned_by event_date,
  physical_properties (
    require_partition_filter = TRUE  -- Prevents full table scans
  )
);
```

**Benefits:**

- Prevents accidental full table scans
- Enforces best practices
- Reduces costs

#### Maximum Bytes Billed

**Set cost limits:**

```sql
MODEL (
  name analytics.experimental_query,
  session_properties (
    'maximum_bytes_billed' = '10000000000'  -- 10GB limit
  )
);
```

**Use for:**

- Experimental queries
- Cost control
- Preventing runaway queries

### 5.3 Databricks/Spark Optimization

#### Partitioning

**Partition by date and other dimensions:**

```sql
MODEL (
  name analytics.events,
  partitioned_by (event_date, event_type),  -- Multi-column partition
  storage_format 'delta'
);
```

**Partition guidelines:**

- **Date columns**: Always partition by date for time-series
- **Low cardinality**: Event type, region (avoid high cardinality)
- **Limit partitions**: Too many partitions = performance degradation

#### Delta Lake Optimization

**Enable auto-optimization:**

```sql
MODEL (
  name analytics.events,
  physical_properties (
    delta.autoOptimize.optimizeWrite = true,  -- Optimize writes
    delta.autoOptimize.autoCompact = true     -- Auto-compact files
  ),
  partitioned_by event_date
);
```

**Benefits:**

- **Optimize writes**: Coalesces small files
- **Auto-compact**: Reduces file count
- **Better performance**: Faster queries

#### Z-Ordering

**Use Z-ordering for multi-column queries:**

```sql
MODEL (
  name analytics.orders,
  partitioned_by order_date,
  -- Z-order by common filter columns (Databricks-specific)
  -- Configured via physical_properties or post_statements
);
```

**Z-ordering example:**

```sql
-- Post-statement to Z-order
MODEL (
  name analytics.orders,
  post_statements [
    'OPTIMIZE analytics.orders ZORDER BY (customer_id, product_id)'
  ]
);
```

#### Resource Allocation

**Configure Spark resources:**

```sql
MODEL (
  name analytics.heavy_processing,
  session_properties (
    'spark.executor.cores' = 4,
    'spark.executor.memory' = '8G',
    'spark.sql.shuffle.partitions' = 200
  )
);
```

**Resource guidelines:**

- **Executor cores**: 2-8 per executor
- **Executor memory**: 4-16GB per executor
- **Shuffle partitions**: 200-400 (adjust based on data size)

### 5.4 Postgres Optimization

#### Indexes

**Create indexes on filter and join columns:**

```sql
MODEL (
  name analytics.orders,
  post_statements [
    'CREATE INDEX idx_customer_id ON analytics.orders(customer_id)',
    'CREATE INDEX idx_order_date ON analytics.orders(order_date)',
    'CREATE INDEX idx_customer_date ON analytics.orders(customer_id, order_date)'
  ]
);
```

**Index types:**

- **B-tree**: Default, good for most queries
- **Hash**: Equality lookups only
- **GIN**: Full-text search, arrays
- **GiST**: Geometric data, full-text search

#### Partitioning

**Partition large tables:**

```sql
MODEL (
  name analytics.events,
  partitioned_by event_date  -- Postgres supports date partitioning
);
```

**Partition strategies:**

- **Range partitioning**: By date ranges
- **List partitioning**: By discrete values
- **Hash partitioning**: Distribute data evenly

#### Vacuum and Analyze

**Maintain table statistics:**

```sql
MODEL (
  name analytics.orders,
  post_statements [
    'ANALYZE analytics.orders'  -- Update statistics for query planner
  ]
);
```

**Benefits:**

- Better query plans
- Accurate row estimates
- Optimal join order

### 5.5 DuckDB Optimization

#### Columnar Storage

**DuckDB is columnar by default - optimize for columnar access:**

```sql
-- ✅ Good: Columnar-friendly queries
SELECT 
  customer_id,
  SUM(amount) as total
FROM orders
GROUP BY customer_id;

-- ❌ Bad: Row-by-row processing
SELECT * FROM orders WHERE complex_function(column);
```

#### Memory Configuration

**Configure memory limits:**

```sql
MODEL (
  name analytics.local_processing,
  session_properties (
    'memory_limit' = '8GB'  -- Limit memory usage
  )
);
```

**Use cases:**

- Local development
- Small to medium datasets
- Fast analytical queries

[↑ Back to Top](#chapter-2d-model-optimization)

---

## 6. Advanced Properties Optimization

### 6.1 Batch Size Optimization

**Optimize `batch_size` for your data:**

```sql
MODEL (
  name analytics.hourly_events,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date,
    batch_size 24  -- Process 24 hours per batch
  ),
  cron '@hourly'
);
```

**Batch size calculation:**

```
Optimal batch_size = 
  (Query timeout limit) / (Time per interval) * 0.8
```

**Example:**

- Query timeout: 1 hour
- Time per interval: 2 minutes
- Optimal batch_size: (60 min / 2 min) * 0.8 = 24 intervals

**Adjust based on performance:**

```sql
-- Start conservative
batch_size 12

-- Increase if stable
batch_size 24

-- Decrease if timeouts occur
batch_size 6
```

### 6.2 Batch Concurrency Optimization

**Control parallel execution:**

```sql
MODEL (
  name analytics.events,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date,
    batch_size 24,
    batch_concurrency 5  -- Max 5 batches in parallel
  )
);
```

**Concurrency guidelines:**

| Warehouse | Recommended Concurrency |
|-----------|----------------------|
| Snowflake | 5-10 per warehouse |
| BigQuery | 20-50 (slot-dependent) |
| Databricks | 10-20 per cluster |
| Postgres | 5-10 per database |

**Monitor and adjust:**

```bash
# Check warehouse utilization
vulcan info

# If queries queue: Increase concurrency
# If timeouts: Decrease concurrency
```

### 6.3 Lookback Optimization

**Balance late data vs performance:**

```sql
MODEL (
  name analytics.orders,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column order_date,
    lookback 3  -- Reprocess last 3 days
  )
);
```

**Lookback impact:**

```
Without lookback: Processes 1 interval
With lookback 7: Processes 8 intervals
Cost: ~8x more expensive
```

**Optimization strategy:**

1. **Start with 0**: `lookback 0`
2. **Monitor late arrivals**: Check for data arriving after processing
3. **Increase gradually**: `lookback 1`, then `lookback 3`, etc.
4. **Monitor performance**: Ensure lookback doesn't cause timeouts

**Measure late-arriving data:**

```sql
-- Check for late arrivals
SELECT 
  order_date,
  COUNT(*) as late_arrivals,
  MAX(created_at) as latest_arrival
FROM raw.orders
WHERE order_date < CURRENT_DATE - INTERVAL '7 days'
  AND created_at > CURRENT_DATE - INTERVAL '1 day'
GROUP BY order_date
ORDER BY late_arrivals DESC;
```

### 6.4 Forward-Only Optimization

**Use forward-only for very large tables:**

```sql
MODEL (
  name analytics.huge_table,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date,
    forward_only TRUE  -- Never rebuild historical data
  )
);
```

**When to use:**

- ✅ Tables with billions of rows
- ✅ Years of historical data
- ✅ Expensive to rebuild
- ✅ Rarely need historical reprocessing

**Tradeoffs:**

- ✅ **Faster deployments**: No backfills
- ✅ **Lower costs**: No historical reprocessing
- ❌ **Less flexible**: Can't easily fix historical data
- ❌ **Schema changes**: Limited by `on_destructive_change`

**Schema change handling:**

```sql
MODEL (
  name analytics.huge_table,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date,
    forward_only TRUE,
    on_destructive_change 'warn',  -- Warn but allow
    on_additive_change 'allow'     -- Allow new columns
  )
);
```

### 6.5 Allow Partials Optimization

**Process incomplete intervals:**

```sql
MODEL (
  name analytics.realtime_metrics,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date
  ),
  allow_partials TRUE  -- Process today even if incomplete
);
```

**Use cases:**

- Real-time dashboards
- Always-on metrics
- Force model to run every time

**Combined with `--ignore-cron`:**

```bash
# Force run even if cron hasn't elapsed
vulcan run --ignore-cron
```

**Performance consideration:**

- Processes incomplete data (may need reprocessing later)
- Useful for real-time use cases
- May cause slight data inconsistencies

### 6.6 Disable Restatement

**Prevent accidental restatements:**

```sql
MODEL (
  name analytics.append_only_log,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key log_id,
    disable_restatement TRUE  -- Never reprocess history
  )
);
```

**Use for:**

- Append-only tables
- Audit logs
- Immutable data

**Benefits:**

- Prevents accidental data loss
- Protects historical data
- Enforces append-only pattern

[↑ Back to Top](#chapter-2d-model-optimization)

---

## 7. Cost Optimization

### 7.1 Warehouse Cost Factors

**Cost components:**

1. **Compute costs**: Query execution time
2. **Storage costs**: Table storage
3. **Data transfer costs**: Moving data between systems

**Optimization targets:**

- Reduce compute time (faster queries)
- Reduce data scanned (partitioning, filtering)
- Reduce storage (partition expiration, compression)

### 7.2 Compute Cost Optimization

#### Reduce Query Execution Time

**Use incremental models:**

```sql
-- ❌ Expensive: Full refresh daily
kind FULL  -- Scans 100M rows daily

-- ✅ Cheap: Incremental daily
kind INCREMENTAL_BY_TIME_RANGE  -- Scans 1M rows daily
```

**Filter early:**

```sql
-- ✅ Good: Filters before expensive operations
SELECT *
FROM (
  SELECT * FROM large_table 
  WHERE event_date = '2024-01-15'  -- Filter first
) filtered
JOIN huge_table h ON filtered.id = h.id;
```

#### Optimize Aggregations

**Pre-aggregate when possible:**

```sql
-- ❌ Expensive: Aggregating billions of events
SELECT 
  customer_id,
  event_date,
  COUNT(*) as event_count
FROM raw.events  -- Billions of rows
GROUP BY customer_id, event_date;

-- ✅ Cheap: Pre-aggregated
SELECT 
  customer_id,
  event_date,
  event_count  -- Pre-computed
FROM analytics.daily_event_summary;  -- Millions of rows
```

#### Use Appropriate Warehouse Size

**Right-size warehouses:**

```sql
-- ❌ Expensive: Over-provisioned
physical_properties (
  warehouse = 'X-LARGE_WH'  -- Too big for workload
)

-- ✅ Optimal: Right-sized
physical_properties (
  warehouse = 'MEDIUM_WH'  -- Appropriate for workload
)
```

### 7.3 Storage Cost Optimization

#### Partition Expiration

**Auto-delete old partitions:**

```sql
MODEL (
  name analytics.events,
  partitioned_by event_date,
  physical_properties (
    partition_expiration_days = 90  -- Delete partitions older than 90 days
  )
);
```

**Benefits:**

- Automatic cleanup
- Lower storage costs
- No manual maintenance

#### Transient Tables

**Use transient tables for temporary data:**

```sql
MODEL (
  name analytics.temp_metrics,
  physical_properties (
    creatable_type = TRANSIENT,  -- Lower cost, no fail-safe
    data_retention_time_in_days = 0  -- No Time Travel
  )
);
```

**When to use:**

- Intermediate models
- Temporary aggregations
- Models rebuilt frequently

#### Compression

**Enable compression (warehouse-specific):**

```sql
-- BigQuery: Automatic compression
-- Snowflake: Automatic compression
-- Databricks: Parquet compression
MODEL (
  name analytics.events,
  storage_format 'parquet'  -- Compressed format
);
```

### 7.4 Data Transfer Cost Optimization

#### Minimize Data Movement

**Process data where it lives:**

```sql
-- ✅ Good: Process in same warehouse
SELECT * FROM warehouse_a.table1
JOIN warehouse_a.table2 ON table1.id = table2.id;

-- ❌ Bad: Cross-warehouse joins (if possible)
SELECT * FROM warehouse_a.table1
JOIN warehouse_b.table2 ON table1.id = table2.id;
```

#### Use Columnar Formats

**Columnar formats reduce transfer:**

```sql
MODEL (
  name analytics.events,
  storage_format 'parquet'  -- Columnar, compressed
);
```

**Benefits:**

- Smaller file sizes
- Faster transfers
- Better compression

### 7.5 Cost Monitoring

**Track costs by model:**

```sql
-- Snowflake: Use query tags
MODEL (
  name analytics.customer_metrics,
  session_properties (
    query_tag = 'analytics_pipeline_customer'
  )
);

-- Query Snowflake query history
SELECT 
  query_tag,
  SUM(total_elapsed_time) as total_time,
  SUM(credits_used) as total_credits
FROM snowflake.account_usage.query_history
WHERE query_tag = 'analytics_pipeline_customer'
GROUP BY query_tag;
```

**Monitor expensive queries:**

```bash
# Check model execution times
vulcan info --select analytics.customer_metrics

# Identify slow models
vulcan dag --select analytics.* --show-execution-times
```

[↑ Back to Top](#chapter-2d-model-optimization)

---

## 8. Troubleshooting Performance

### 8.1 Identifying Performance Issues

#### Slow Query Symptoms

**Common signs:**

- Query execution time > 10 minutes
- Timeout errors
- High warehouse utilization
- Downstream models waiting

#### Diagnostic Queries

**Check model execution times:**

```bash
# View execution history
vulcan info --select analytics.slow_model

# Check for timeouts
vulcan run --select analytics.slow_model --verbose
```

**Query warehouse query history:**

```sql
-- Snowflake
SELECT 
  query_text,
  total_elapsed_time,
  bytes_scanned,
  partitions_scanned,
  partitions_total
FROM snowflake.account_usage.query_history
WHERE query_text LIKE '%analytics.slow_model%'
ORDER BY total_elapsed_time DESC
LIMIT 10;

-- BigQuery
SELECT 
  job_id,
  creation_time,
  total_bytes_processed,
  total_slot_ms
FROM `region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE statement_type = 'SELECT'
  AND creation_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
ORDER BY total_slot_ms DESC
LIMIT 10;
```

### 8.2 Common Performance Issues

#### Issue 1: Full Table Scans

**Symptoms:**
- Query scans entire table
- High bytes scanned
- Slow execution

**Solution:**

```sql
-- ❌ Problem: No partition filter
SELECT * FROM analytics.events;

-- ✅ Fix: Add partition filter
SELECT * FROM analytics.events
WHERE event_date BETWEEN @start_ds AND @end_ds;
```

**Prevention:**

```sql
MODEL (
  name analytics.events,
  partitioned_by event_date,
  physical_properties (
    require_partition_filter = TRUE  -- Force partition filtering
  )
);
```

#### Issue 2: Large Backfills

**Symptoms:**
- Timeout errors
- Memory issues
- Long execution times

**Solution:**

```sql
-- ❌ Problem: No batching
MODEL (
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_date)
  -- Processes all missing intervals in one job
);

-- ✅ Fix: Add batch_size
MODEL (
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date,
    batch_size 7  -- Process 7 days per batch
  )
);
```

#### Issue 3: Inefficient Joins

**Symptoms:**
- Cartesian products
- Slow join operations
- High memory usage

**Solution:**

```sql
-- ❌ Problem: Missing join condition
SELECT *
FROM table1 t1
JOIN table2 t2;  -- Cartesian product!

-- ✅ Fix: Add join condition
SELECT *
FROM table1 t1
JOIN table2 t2 ON t1.id = t2.id;

-- ✅ Better: Filter before join
SELECT *
FROM (
  SELECT * FROM table1 WHERE filter_condition
) t1
JOIN table2 t2 ON t1.id = t2.id;
```

#### Issue 4: Too Much Lookback

**Symptoms:**
- Processes too many intervals
- High costs
- Slow execution

**Solution:**

```sql
-- ❌ Problem: Excessive lookback
lookback 30  -- Reprocesses 30 days every run

-- ✅ Fix: Reduce lookback
lookback 3  -- Only reprocess last 3 days

-- ✅ Better: Monitor late arrivals first
-- Only add lookback if needed
```

#### Issue 5: Resource Contention

**Symptoms:**
- Queries queuing
- Timeouts
- Warehouse overload

**Solution:**

```sql
-- ❌ Problem: Too much concurrency
batch_concurrency 20  -- Overloads warehouse

-- ✅ Fix: Reduce concurrency
batch_concurrency 5  -- Appropriate for warehouse size
```

### 8.3 Performance Debugging Workflow

**Step 1: Identify slow models**

```bash
# Check execution times
vulcan info --select analytics.*

# Find slowest models
vulcan dag --show-execution-times | sort -k2 -rn
```

**Step 2: Analyze query plans**

```bash
# View optimized SQL
vulcan render analytics.slow_model > slow_model.sql

# Check query plan in warehouse
-- Run EXPLAIN PLAN in warehouse
```

**Step 3: Check warehouse metrics**

```sql
-- Snowflake: Check warehouse utilization
SELECT 
  warehouse_name,
  AVG(avg_running) as avg_queries_running,
  AVG(avg_queued) as avg_queries_queued
FROM snowflake.account_usage.warehouse_load_history
WHERE start_time > CURRENT_TIMESTAMP - INTERVAL '1 day'
GROUP BY warehouse_name;
```

**Step 4: Optimize incrementally**

1. **Add partitioning** (if missing)
2. **Add batch_size** (if large backfills)
3. **Reduce lookback** (if excessive)
4. **Optimize queries** (filter early, efficient joins)
5. **Add indexes** (if supported)

**Step 5: Monitor improvements**

```bash
# Re-run and compare
vulcan run --select analytics.slow_model

# Check execution time improvement
vulcan info --select analytics.slow_model
```

### 8.4 Performance Testing

**Test optimizations in development:**

```bash
# Create dev environment
vulcan plan dev

# Test with limited data
vulcan run dev --start '30 days ago' --end 'today'

# Compare execution times
vulcan info dev --select analytics.test_model
```

**Benchmark before/after:**

```bash
# Before optimization
time vulcan run --select analytics.slow_model
# Result: 45 minutes

# After optimization
time vulcan run --select analytics.slow_model
# Result: 5 minutes (9x improvement!)
```

[↑ Back to Top](#chapter-2d-model-optimization)

---

## 9. Best Practices

### 9.1 Model Design Best Practices

#### Start with Incremental

**Default to incremental for time-series:**

```sql
-- ✅ Good: Incremental by default
MODEL (
  name analytics.events,
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_date)
);

-- ❌ Bad: FULL unless necessary
MODEL (
  name analytics.events,
  kind FULL  -- Only if < 1M rows or non-temporal
);
```

#### Partition by Time

**Always partition time-series tables:**

```sql
MODEL (
  name analytics.events,
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_date),
  partitioned_by event_date  -- Essential for performance
);
```

#### Filter Early

**Always filter in WHERE clause:**

```sql
-- ✅ Good: Filter in query
SELECT *
FROM raw.events
WHERE event_date BETWEEN @start_ds AND @end_ds;

-- ❌ Bad: No filter
SELECT * FROM raw.events;
```

### 9.2 Property Optimization Best Practices

#### Conservative Defaults

**Start conservative, optimize based on data:**

```sql
-- Start with defaults
MODEL (
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_date)
  -- No batch_size, no lookback
);

-- Add optimizations as needed
MODEL (
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date,
    batch_size 7,      -- Add if timeouts occur
    lookback 3         -- Add if late data issues
  )
);
```

#### Monitor and Adjust

**Regular performance reviews:**

1. **Weekly**: Check execution times
2. **Monthly**: Review costs
3. **Quarterly**: Optimize slow models

**Performance checklist:**

- [ ] Execution time < 10 minutes
- [ ] No timeout errors
- [ ] Appropriate batch_size
- [ ] Lookback not excessive
- [ ] Partitioning enabled
- [ ] Queries use partition filters

### 9.3 Warehouse-Specific Best Practices

#### Snowflake

- ✅ Use appropriate warehouse size
- ✅ Enable query tagging for monitoring
- ✅ Use transient tables for temp data
- ✅ Cluster by high-cardinality columns

#### BigQuery

- ✅ Always partition time-series tables
- ✅ Require partition filters
- ✅ Cluster by filter columns
- ✅ Set partition expiration

#### Databricks

- ✅ Enable Delta Lake auto-optimization
- ✅ Partition by date
- ✅ Z-order by filter columns
- ✅ Configure Spark resources appropriately

### 9.4 Cost Optimization Best Practices

#### Right-Size Resources

**Use smallest warehouse that meets needs:**

```sql
-- ❌ Over-provisioned
physical_properties (warehouse = 'X-LARGE_WH')

-- ✅ Right-sized
physical_properties (warehouse = 'MEDIUM_WH')
```

#### Monitor Costs

**Track costs by model/pipeline:**

```sql
-- Tag queries
session_properties (query_tag = 'pipeline_name')

-- Query cost history
SELECT 
  query_tag,
  SUM(credits_used) as total_cost
FROM query_history
GROUP BY query_tag;
```

#### Use Incremental Models

**Biggest cost savings:**

```sql
-- ❌ Expensive: Full refresh
kind FULL  -- Scans entire table daily

-- ✅ Cheap: Incremental
kind INCREMENTAL_BY_TIME_RANGE  -- Scans only new data
```

### 9.5 Production Optimization Checklist

**Before deploying to production:**

- [ ] Model uses appropriate `kind` (incremental for time-series)
- [ ] Partitioning enabled (for time-series)
- [ ] WHERE clause filters by time range
- [ ] `batch_size` set (if large backfills)
- [ ] `batch_concurrency` appropriate for warehouse
- [ ] `lookback` not excessive
- [ ] Query execution time < 10 minutes
- [ ] No timeout errors in testing
- [ ] Cost monitoring enabled (query tags)
- [ ] Performance tested in dev environment

**Ongoing optimization:**

- [ ] Weekly performance review
- [ ] Monthly cost review
- [ ] Quarterly optimization pass
- [ ] Monitor for slow queries
- [ ] Adjust batch_size/lookback as needed

[↑ Back to Top](#chapter-2d-model-optimization)

---

## 10. Summary and Next Steps

### What You've Learned

This chapter covered comprehensive model optimization strategies:

1. **Performance Fundamentals**: Understanding bottlenecks, incremental vs full refresh, batch processing
2. **Model Kinds Optimization**: Choosing and optimizing each model kind
3. **Query Optimization**: SQL best practices, SQLGlot optimizer, CTEs, subqueries
4. **Warehouse-Specific Optimization**: Snowflake, BigQuery, Databricks, Postgres, DuckDB
5. **Advanced Properties Optimization**: batch_size, batch_concurrency, lookback, forward_only
6. **Cost Optimization**: Compute, storage, data transfer costs
7. **Troubleshooting Performance**: Identifying and fixing common issues
8. **Best Practices**: Production optimization checklist

### Key Takeaways

**1. Use Incremental Models**
- 10-100x faster than full refresh
- 10-100x lower costs
- Essential for time-series data

**2. Partition by Time**
- Always partition time-series tables
- Enables partition pruning
- Reduces data scanned

**3. Filter Early**
- Always filter in WHERE clause
- Filter before joins
- Use partition filters

**4. Right-Size Resources**
- Appropriate warehouse size
- Appropriate batch_size
- Appropriate batch_concurrency

**5. Monitor and Optimize**
- Track execution times
- Monitor costs
- Adjust based on data

### Next Steps

**Immediate:**
1. Review your models for optimization opportunities
2. Add partitioning to time-series models
3. Optimize slow models (add batch_size, reduce lookback)
4. Enable cost monitoring (query tags)

**Short-term:**
5. Optimize warehouse-specific settings
6. Review and optimize queries
7. Set up performance monitoring
8. Document optimization decisions

**Long-term:**
9. Regular performance reviews
10. Cost optimization initiatives
11. Warehouse migration optimization
12. Advanced optimization techniques

### Related Chapters

- **[Chapter 2: Models](index.md)** - Foundation concepts
- **[Chapter 2A: Model Properties](model-properties.md)** - Complete property reference
- **[Chapter 2C: Model Operations](model-operations.md)** - Advanced patterns

---

**Ready to optimize your models?** Start by reviewing your slowest models and applying the optimization strategies from this chapter.

[↑ Back to Top](#chapter-2d-model-optimization)

