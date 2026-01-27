# Vulcan Terminology Guide

When you're working with Vulcan, you'll encounter terms that might be unfamiliar. This guide explains what they mean and why they matter. Each term links to detailed documentation where you can dive deeper.

---

## Model Terms

These control how your models behave and how Vulcan processes them.

| Term | Definition | Documentation |
|------|------------|---------------|
| **Grain** | The column or columns that make each row unique. Like declaring a primary key, but Vulcan uses this for table comparisons and semantic layer joins. | [Model Properties](components/model/properties.md#grain--grains) |
| **References** | Foreign key columns that tell Vulcan how models relate to each other. The semantic layer uses these to detect joins automatically. | [Model Properties](components/model/properties.md#references) |
| **Model Kind** | How Vulcan processes your data. FULL rebuilds everything, INCREMENTAL only processes new intervals, VIEW computes on-demand. | [Model Kinds](components/model/model_kinds.md) |
| **Cron** | Schedule expression that sets when your model runs. Use `@daily` for nightly refreshes or standard cron syntax for custom schedules. | [Model Properties](components/model/properties.md#cron) |
| **Interval** | A time period Vulcan tracks for incremental models. Each day, week, or hour becomes an interval that gets processed independently. | [Incremental Models](guides/incremental_by_time.md) |
| **Backfill** | Loading historical data when you first create a model or after changing logic. Vulcan figures out which intervals need processing. | [Plans](references/plans.md) |
| **Lookback** | How many intervals to reprocess for late-arriving data. Handles events that show up after their time window already passed. | [Model Kinds](components/model/model_kinds.md#incremental_by_time_range) |
| **Forward-only** | Models that never rebuild historical data. Use when past data is immutable or reprocessing costs too much. | [Model Kinds](components/model/model_kinds.md) |
| **Owner** | Team or person responsible for a model. Used for notifications and knowing who to contact when something breaks. | [Model Properties](components/model/properties.md#owner) |
| **Description** | Human-readable explanation of what your model does. Vulcan registers this as a table comment, so it shows up in BI tools. | [Model Properties](components/model/properties.md#description) |
| **Depends On** | Explicit dependency list. Required for Python models since Vulcan can't auto-detect dependencies from Python code. | [Model Properties](components/model/properties.md#depends_on) |

---

## Execution Terms

These describe how Vulcan applies changes and processes data.

| Term | Definition | Documentation |
|------|------------|---------------|
| **Plan** | Summary of what will change before you deploy. Shows affected models, intervals that need processing, and the full impact of your changes. | [Plans](references/plans.md) |
| **Run** | Scheduled execution that processes new data intervals. Different from plan: plan applies code changes, run handles regular data processing. | [Run and Scheduling](guides/run_and_scheduling.md) |
| **Virtual Environment** | Isolated testing space that can share tables when safe. Test changes without touching production, roll back if needed. | [Plans](references/plans.md#plan-application) |
| **Virtual Layer** | Views that point to physical tables. This is what you interact with most of the time, not the raw storage underneath. | [Plans](references/plans.md) |
| **Physical Layer** | Actual database tables and materialized views where your data lives. Vulcan manages this automatically. | [Plans](references/plans.md) |

---

## Semantic Layer Terms

These transform your technical tables into something business users can query without SQL.

| Term | Definition | Documentation |
|------|------------|---------------|
| **Semantic Layer** | Translation layer that maps physical models to business concepts. Turns `analytics.daily_revenue_metrics` into "Monthly Revenue by Customer Tier" that anyone can query. | [Semantic Layer Overview](components/semantics/overview.md) |
| **Semantic Model** | Maps a physical Vulcan model to a semantic representation. Provides business aliases and exposes dimensions, measures, segments, and joins. | [Semantic Models](components/semantics/models.md) |
| **Dimensions** | Attributes for grouping and filtering. Answer "by what?" questions. Your model columns become dimensions automatically. | [Semantic Models](components/semantics/models.md#dimensions) |
| **Measures** | Aggregated calculations. Answer "how much?" or "how many?" using SQL expressions like `SUM(amount)` or `COUNT(*)`. | [Semantic Models](components/semantics/models.md#measures) |
| **Segments** | Reusable filter conditions. Define subsets like "active customers" or "high-value orders" that you can reuse across queries. | [Semantic Models](components/semantics/models.md#segments) |
| **Joins** | Relationships between semantic models. Enable cross-model analysis, like combining order data with customer data automatically. | [Semantic Models](components/semantics/models.md#joins) |
| **Business Metrics** | Complete analytical definitions that combine measures with dimensions and time. Ready for time-series analysis and automatic API generation. | [Business Metrics](components/semantics/business_metrics.md) |
| **Proxy Dimensions** | Expose measures from joined models as dimensions. Lets you filter or group by aggregated values from other models. | [Semantic Models](components/semantics/models.md#cross-model-analysis) |
| **Transpilation** | Convert semantic queries to executable SQL. Validate and debug business-friendly queries before they hit your database. | [Transpiling Semantics](guides/transpiling_semantics.md) |

---

## Data Quality Terms

These ensure data integrity. The difference between catching problems early and discovering them at 3 AM.

| Term | Definition | Documentation |
|------|------------|---------------|
| **Assertions / Audits** | SQL queries that validate data after execution. Always blocking: if they find bad data, execution stops immediately. | [Audits](components/audits/audits.md) |
| **Checks** | Quality monitoring rules configured in YAML. Non-blocking validation that tracks trends and detects anomalies over time. | [Data Quality](guides/data_quality.md) |

---

## Architecture Terms

These describe how Vulcan structures and tracks your pipeline.

| Term | Definition | Documentation |
|------|------------|---------------|
| **DAG** | Directed Acyclic Graph. Structure Vulcan uses to track model dependencies and figure out the correct execution order. | [Glossary](references/glossary.md#dag) |
| **Lineage** | Visualization of how data flows from sources to consumption. See how changes propagate through your pipeline. | [Glossary](references/glossary.md#lineage) |

---

## How These Terms Fit Together

You don't need to memorize everything. Here's how these concepts connect in practice:

→ **Models** define your logic

→ **Grain** documents structure

→ **Model Kind** determines processing

→ **Cron** sets schedule

→ **Plan** reviews changes

→ **Run** processes data

→ **Assertions** validate quality

→ **Semantic Layer** exposes business interface

→ **Dimensions** and **Measures** enable self-service analytics

Each term solves a specific problem. Grain helps with comparisons. References enable automatic joins. Model Kinds optimize performance. The Semantic Layer makes data accessible to non-technical users.

---

*Click any documentation link above for detailed guides with examples, best practices, and advanced patterns.*
