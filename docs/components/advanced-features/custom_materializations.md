# Custom materializations

Vulcan comes with a variety of [model kinds](../../model/model_kinds.md) that handle the most common ways to evaluate and materialize your data transformations. But what if you need something different?

Sometimes, your specific use case doesn't quite fit any of the built-in model kinds. Maybe you need custom logic for how data gets inserted, or you want to implement a materialization strategy that's unique to your workflow. That's where custom materializations come in, they let you write your own Python code to control exactly how your models get materialized.

!!! warning "Advanced Feature"
    Custom materializations are powerful, but they're also advanced. Before diving in, make sure you've exhausted all other options. If you're considering this path, we'd love to hear from you in our [community slack](https://tobikodata.com/community.html). If an existing model kind can solve your problem, we want to improve our docs; if a built-in kind is almost what you need, we might be able to enhance it for everyone.

## What is a materialization?

Think of a materialization as the "how" behind your model execution. When Vulcan runs a model, it needs to figure out how to actually get that data into your database. The materialization is the set of methods that handle executing your transformation logic and managing the resulting data.

Some materializations are straightforward. For example, a `FULL` model kind completely replaces the table each time it runs, so its materialization is essentially just `CREATE OR REPLACE TABLE [name] AS [your query]`. Simple!

Other materializations are more complex. An `INCREMENTAL_BY_TIME_RANGE` model needs to figure out which time intervals to process, query only that data, and then merge it into the existing table. That requires more logic.

The materialization logic can also vary by SQL engine. PostgreSQL doesn't support `CREATE OR REPLACE TABLE`, so `FULL` models on Postgres use `DROP` then `CREATE` instead. Vulcan handles all these engine-specific details for built-in model kinds, but with custom materializations, you're in control.

## How custom materializations work

Custom materializations are like creating your own model kind. You define them in Python, give them a name, and then reference that name in your model's `MODEL` block. They can even accept configuration arguments that you pass in from your model definition.

Here's what every custom materialization needs:

- **Python code**: Written as a Python class
- **Base class**: Must inherit from Vulcan's `CustomMaterialization` class
- **Insert method**: At minimum, you need to implement the `insert` method
- **Auto-loading**: Vulcan automatically discovers materializations in your `materializations/` directory

You can also:

- Override other methods from `MaterializableStrategy` or `EngineAdapter` classes
- Execute arbitrary SQL using the engine adapter
- Perform Python processing with Pandas or other libraries (though for most cases, you'd want that logic in a [Python model](../../model/types/python_models.md) instead)

Vulcan will automatically load any Python files in your project's `materializations/` directory. Or, if you prefer, you can package your materialization as a [Python package](#python-packaging) and install it like any other dependency.

## Creating a custom materialization

To create a custom materialization, just add a `.py` file to your project's `materializations/` folder. Vulcan will automatically import all Python modules in this folder when your project loads, so your materializations will be ready to use.

Your materialization class needs to inherit from `CustomMaterialization` and implement at least the `insert` method. Let's look at some examples to see how this works.

### Simple example

Here's a complete example that shows custom insert logic with some helpful logging:

```python linenums="1"
import typing as t
from sqlalchemy import text
from vulcan import CustomMaterialization
from vulcan import Model

class SimpleCustomMaterialization(CustomMaterialization):
    """Simple custom materialization - demonstrates custom insert logic"""
    
    NAME = "simple_custom"
    
    def insert(
        self,
        table_name: str,
        query_or_df: t.Union[str, t.Any],
        model: Model,
        is_first_insert: bool,
        render_kwargs: t.Dict[str, t.Any],
        **kwargs: t.Any,
    ) -> None:
        """Custom insert logic for tables"""
        
        print(f"Custom materialization: Processing table {table_name}")
        print(f"Model: {model.name}")
        print(f"Is first insert: {is_first_insert}")
        
        if is_first_insert:
            print("Creating table for the first time")
            # Create the table normally using the adapter
            self.adapter.create_table(
                table_name,
                columns=model.columns_to_types,
                target_columns_to_types=model.columns_to_types,
                partitioned_by=model.partitioned_by,
            )
        
        # Insert data with custom logic
        if isinstance(query_or_df, str):
            print("Executing SQL query")
            # Execute the query - Vulcan provides the INSERT INTO ... SELECT query
            self.adapter.execute(text(query_or_df))
        else:
            print("Inserting DataFrame")
            # Insert DataFrame normally - useful for Python models that return DataFrames
            self.adapter.insert_append(table_name, query_or_df)
        
        print(f"Custom materialization completed for {table_name}")
```

Let's break down what's happening here:

| Component | What It Does |
|-----------|--------------|
| `NAME` | The identifier you'll use in your model definition (like `simple_custom`) |
| `table_name` | The target table where your data will be inserted |
| `query_or_df` | Either a SQL query string or a DataFrame (works with Pandas, PySpark, Snowpark) |
| `model` | The full model definition object, gives you access to all model properties |
| `is_first_insert` | `True` if this is the first time inserting data for this model version |
| `render_kwargs` | Dictionary of arguments used to render the model query |
| `self.adapter` | The engine adapter, your interface to execute SQL and interact with the database |

### Minimal example

If you just want a simple full-refresh materialization, here's the minimal version:

```python linenums="1"
from vulcan import CustomMaterialization
from vulcan import Model
import typing as t

class CustomFullMaterialization(CustomMaterialization):
    NAME = "my_custom_full"

    def insert(
        self,
        table_name: str,
        query_or_df: t.Any,
        model: Model,
        is_first_insert: bool,
        render_kwargs: t.Dict[str, t.Any],
        **kwargs: t.Any,
    ) -> None:
        self.adapter.replace_query(table_name, query_or_df)
```

That's it! This will completely replace the table contents each time the model runs, just like a `FULL` model kind.

### Controlling table creation and deletion

You can also customize how tables and views are created and deleted by overriding the `create` and `delete` methods:

```python linenums="1"
from vulcan import CustomMaterialization
from vulcan import Model
import typing as t

class CustomFullMaterialization(CustomMaterialization):
    NAME = "my_custom_full"
    
    def insert(self, table_name: str, query_or_df: t.Any, model: Model, 
               is_first_insert: bool, render_kwargs: t.Dict[str, t.Any], **kwargs: t.Any) -> None:
        self.adapter.replace_query(table_name, query_or_df)

    def create(
        self,
        table_name: str,
        model: Model,
        is_table_deployable: bool,
        render_kwargs: t.Dict[str, t.Any],
        **kwargs: t.Any,
    ) -> None:
        # Custom table/view creation logic
        # Uses self.adapter methods like create_table, create_view, or ctas
        self.adapter.create_table(
            table_name,
            columns=model.columns_to_types,
            target_columns_to_types=model.columns_to_types,
        )

    def delete(self, name: str, **kwargs: t.Any) -> None:
        # Custom table/view deletion logic
        self.adapter.drop_table(name)
```

This gives you full control over the lifecycle of your data objects.

## Using a custom materialization

Once you've created your materialization, using it is straightforward. In your model definition, set the `kind` to `CUSTOM` and specify the `materialization` name (the `NAME` from your Python class):

=== "SQL"

    ```sql linenums="1"
    MODEL (
      name vulcan_demo.custom_model,
      kind CUSTOM (
        materialization 'simple_custom'
      ),
      grain (customer_id)
    );

    SELECT
      c.customer_id,
      c.name AS customer_name,
      COUNT(DISTINCT o.order_id) AS total_orders,
      COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_spent
    FROM vulcan_demo.customers c
    LEFT JOIN vulcan_demo.orders o ON c.customer_id = o.customer_id
    LEFT JOIN vulcan_demo.order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_id, c.name
    ORDER BY total_spent DESC
    ```

=== "Python"

    ```python linenums="1"
    import typing as t
    import pandas as pd
    from datetime import datetime
    from vulcan import ExecutionContext, model
    from vulcan import ModelKindName

    @model(
        "vulcan_demo.custom_model_py",
        columns={
            "customer_id": "int",
            "customer_name": "string",
            "total_orders": "int",
            "total_spent": "decimal(10,2)",
        },
        kind=dict(
            name=ModelKindName.CUSTOM,
            materialization="simple_custom",
        ),
        grain=["customer_id"],
        depends_on=["vulcan_demo.customers", "vulcan_demo.orders", "vulcan_demo.order_items"],
    )
    def execute(
        context: ExecutionContext,
        start: datetime,
        end: datetime,
        execution_time: datetime,
        **kwargs: t.Any,
    ) -> pd.DataFrame:
        """Python model using custom materialization with dynamic dependencies"""
        
        # Simple customer summary
        query = """
        SELECT 
            c.customer_id,
            c.name as customer_name,
            COUNT(DISTINCT o.order_id) as total_orders,
            COALESCE(SUM(oi.quantity * oi.unit_price), 0) as total_spent
        FROM vulcan_demo.customers c
        LEFT JOIN vulcan_demo.orders o ON c.customer_id = o.customer_id
        LEFT JOIN vulcan_demo.order_items oi ON o.order_id = oi.order_id
        GROUP BY c.customer_id, c.name
        ORDER BY total_spent DESC
        """
        
        # Execute query and return results
        return context.fetchdf(query)
    ```

### Passing properties to the materialization

You can pass configuration to your materialization using `materialization_properties`. This is useful when you want to customize behavior per model:

```sql linenums="1"
MODEL (
  name vulcan_demo.custom_model,
  kind CUSTOM (
    materialization 'simple_custom',
    materialization_properties (
      'config_key' = 'config_value',
      'batch_size' = 1000
    )
  )
);
```

Then access these properties in your materialization code via `model.custom_materialization_properties`:

```python linenums="1"
class SimpleCustomMaterialization(CustomMaterialization):
    NAME = "simple_custom"

    def insert(
        self,
        table_name: str,
        query_or_df: t.Any,
        model: Model,
        is_first_insert: bool,
        render_kwargs: t.Dict[str, t.Any],
        **kwargs: t.Any,
    ) -> None:
        # Access custom properties
        config_value = model.custom_materialization_properties.get("config_key")
        batch_size = model.custom_materialization_properties.get("batch_size", 500)
        
        print(f"Config value: {config_value}, Batch size: {batch_size}")
        
        # Proceed with insert logic
        self.adapter.replace_query(table_name, query_or_df)
```

This lets you create flexible materializations that can adapt to different use cases.

## Extending `CustomKind`

!!! warning
    This is advanced territory. You're working with Vulcan's internals here, so there's extra complexity involved. If the basic custom materialization approach works for you, stick with that. Only dive into this if you really need the extra control.

Most of the time, the standard custom materialization approach is all you need. But sometimes you want tighter integration with Vulcan's internals, maybe you need to validate custom properties before any database connections are made, or you want to leverage functionality that depends on specific properties being present.

In those cases, you can create a subclass of `CustomKind` that Vulcan will use instead of the default. When your project loads, Vulcan will detect your subclass and use it instead of the standard `CustomKind`.

### Creating a custom kind

Here's how you'd create a custom kind that validates a `primary_key` property:

```python linenums="1"
import typing as t
from typing_extensions import Self
from pydantic import model_validator
from sqlglot import exp
from vulcan import CustomKind
from vulcan.utils.pydantic import list_of_fields_validator
from vulcan.utils.errors import ConfigError

class MyCustomKind(CustomKind):

    _primary_key: t.List[exp.Expression]

    @model_validator(mode="after")
    def _validate_model(self) -> Self:
        self._primary_key = list_of_fields_validator(
            self.materialization_properties.get("primary_key"),
            {"dialect": self.dialect}
        )
        if not self.primary_key:
            raise ConfigError("primary_key must be specified")
        return self

    @property
    def primary_key(self) -> t.List[exp.Expression]:
        return self._primary_key
```

### Using the custom kind in a model

Use it in your model like this:

```sql linenums="1"
MODEL (
  name vulcan_demo.my_model,
  kind CUSTOM (
    materialization 'my_custom_full',
    materialization_properties (
      primary_key = (col1, col2)
    )
  )
);
```

### Linking to your materialization

To connect your custom kind to your materialization, specify it as a generic type parameter:

```python linenums="1"
class CustomFullMaterialization(CustomMaterialization[MyCustomKind]):
    NAME = "my_custom_full"

    def insert(
        self,
        table_name: str,
        query_or_df: t.Any,
        model: Model,
        is_first_insert: bool,
        render_kwargs: t.Dict[str, t.Any],
        **kwargs: t.Any,
    ) -> None:
        assert isinstance(model.kind, MyCustomKind)

        self.adapter.merge(
            ...,
            unique_key=model.kind.primary_key
        )
```

When Vulcan loads your materialization, it inspects the type signature for generic parameters that are subclasses of `CustomKind`. If it finds one, it uses your subclass when building `model.kind` instead of the default.

Why would you want this? Two main benefits:

- **Early validation**: Your `primary_key` validation happens at load time, not evaluation time. Issues get caught before you even create a plan.
- **Type safety**: `model.kind` resolves to your custom kind object, so you get access to extra properties without additional validation.

## Sharing custom materializations

Once you've built a custom materialization, you'll probably want to use it across multiple projects. You have a couple of options.

### Copying files

The simplest approach is to copy the materialization code into each project's `materializations/` directory. It works, but it's not the most maintainable approach, you'll need to manually update each copy when you make changes.

If you go this route, we strongly recommend keeping the materialization code in version control and setting up a reliable way to notify users when updates are available.

### Python packaging

A more robust approach is to package your materialization as a Python package. This is especially useful if you're using Airflow or other external schedulers where the scheduler cluster doesn't have direct access to your project's `materializations/` folder.

Package your materialization using [setuptools entrypoints](https://packaging.python.org/en/latest/guides/creating-and-discovering-plugins/#using-package-metadata):

=== "pyproject.toml"

    ```toml
    [project.entry-points."vulcan.materializations"]
    my_materialization = "my_package.my_materialization:CustomFullMaterialization"
    ```

=== "setup.py"

    ```python
    setup(
        ...,
        entry_points={
            "vulcan.materializations": [
                "my_materialization = my_package.my_materialization:CustomFullMaterialization",
            ],
        },
    )
    ```

Once the package is installed, Vulcan automatically discovers and loads your materialization from the entrypoint list. No manual configuration needed!

For more details on Python packaging, check out the Vulcan GitHub [custom_materializations](https://github.com/TobikoData/vulcan/tree/main/examples/custom_materializations) example.
