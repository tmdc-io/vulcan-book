# Custom materializations

Vulcan supports a variety of [model kinds](../concepts/models/model_kinds.md) that reflect the most common approaches to evaluating and materializing data transformations.

Sometimes, however, a specific use case cannot be addressed with an existing model kind. For scenarios like this, Vulcan allows users to create their own materialization implementation using Python.

!!! warning "Advanced Feature"
    This is an advanced feature and should only be considered if all other approaches have been exhausted. If you're at this decision point, we recommend you reach out to our team in the [community slack](https://tobikodata.com/community.html) before investing time building a custom materialization. If an existing model kind can solve your problem, we want to clarify the Vulcan documentation; if an existing kind can _almost_ solve your problem, we want to consider modifying the kind so all Vulcan users can benefit.

## Background

A Vulcan model kind consists of methods for executing and managing the outputs of data transformations - collectively, these are the kind's "materialization."

Some materializations are relatively simple. For example, the SQL [FULL model kind](../concepts/models/model_kinds.md#full) completely replaces existing data each time it is run, so its materialization boils down to executing `CREATE OR REPLACE [table name] AS [your model query]`.

The materializations for other kinds, such as [INCREMENTAL BY TIME RANGE](../concepts/models/model_kinds.md#incremental_by_time_range), require additional logic to process the correct time intervals and replace/insert their results into an existing table.

A model kind's materialization may differ based on the SQL engine executing the model. For example, PostgreSQL does not support `CREATE OR REPLACE TABLE`, so `FULL` model kinds instead `DROP` the existing table then `CREATE` a new table. Vulcan already contains the logic needed to materialize existing model kinds on all supported engines.

## Overview

Custom materializations are analogous to new model kinds. Users [specify them by name](#using-a-custom-materialization) in a model definition's `MODEL` block, and they may accept user-specified arguments.

A custom materialization must:

- Be written in Python code
- Be a Python class that inherits the Vulcan `CustomMaterialization` base class
- Use or override the `insert` method from the Vulcan [`MaterializableStrategy`](https://github.com/TobikoData/vulcan/blob/034476e7f64d261860fd630c3ac56d8a9c9f3e3a/vulcan/core/snapshot/evaluator.py#L1146) class/subclasses
- Be loaded or imported by Vulcan at runtime

A custom materialization may:

- Use or override methods from the Vulcan [`MaterializableStrategy`](https://github.com/TobikoData/vulcan/blob/034476e7f64d261860fd630c3ac56d8a9c9f3e3a/vulcan/core/snapshot/evaluator.py#L1146) class/subclasses
- Use or override methods from the Vulcan [`EngineAdapter`](https://github.com/TobikoData/vulcan/blob/034476e7f64d261860fd630c3ac56d8a9c9f3e3a/vulcan/core/engine_adapter/base.py#L67) class/subclasses
- Execute arbitrary SQL code and fetch results with the engine adapter `execute` and related methods

A custom materialization may perform arbitrary Python processing with Pandas or other libraries, but in most cases that logic should reside in a [Python model](../concepts/models/python_models.md) instead of the materialization.

A Vulcan project will automatically load any custom materializations present in its `materializations/` directory. Alternatively, the materialization may be bundled into a [Python package](#python-packaging) and installed with standard methods.

## Creating a custom materialization

Create a new custom materialization by adding a `.py` file containing the implementation to the `materializations/` folder in the project directory. Vulcan will automatically import all Python modules in this folder at project load time and register the custom materializations.

A custom materialization must be a class that inherits the `CustomMaterialization` base class and provides an implementation for the `insert` method.

### Simple example

Here's a complete example of a custom materialization that demonstrates custom insert logic:

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

Let's break down this materialization:

| Component | Description |
|-----------|-------------|
| `NAME` | The name used to reference this materialization in model definitions (`simple_custom`) |
| `table_name` | The target table name where data will be inserted |
| `query_or_df` | Either a SQL query string or a DataFrame (Pandas, PySpark, Snowpark) |
| `model` | The model definition object with access to all model properties |
| `is_first_insert` | `True` if this is the first insert for the current model version |
| `render_kwargs` | Dictionary of arguments used to render the model query |
| `self.adapter` | The engine adapter for executing SQL and interacting with the database |

### Minimal example

For a simpler full-refresh materialization:

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

### Controlling table creation and deletion

You can control how data objects (tables, views, etc.) are created and deleted by overriding the `create` and `delete` methods:

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

## Using a custom materialization

Specify the model kind `CUSTOM` in a model definition to use a custom materialization. Set the `materialization` attribute to the `NAME` from your custom materialization:

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

A custom materialization can accept configuration through `materialization_properties`:

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

Access these properties in your materialization via `model.custom_materialization_properties`:

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

## Extending `CustomKind`

!!! warning
    This is even lower level usage that contains extra complexity and relies on knowledge of Vulcan internals.
    If you don't need this level of complexity, stick with the method described above.

In many cases, the above usage of a custom materialization will suffice. However, you may want tighter integration with Vulcan's internals:

- Validate custom properties before any database connections are made
- Leverage existing functionality that relies on specific properties being present

In this case, you can provide a subclass of `CustomKind` for Vulcan to use instead of `CustomKind` itself. During project load, Vulcan will instantiate your *subclass* instead of `CustomKind`.

### Creating a custom kind

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

Specify the custom kind as a generic type parameter on your materialization class:

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

When Vulcan loads your custom materialization, it will inspect the Python type signature for generic parameters that are subclasses of `CustomKind`. If found, it will instantiate your subclass when building `model.kind` instead of using the default `CustomKind` class.

Benefits of this approach:

- **Early validation**: Validation for `primary_key` happens at load time instead of evaluation time, so issues are caught before applying a plan
- **Type safety**: `model.kind` resolves to your custom kind object, giving access to extra properties without additional validation

## Sharing custom materializations

### Copying files

The simplest (but least robust) way to use a custom materialization in multiple Vulcan projects is for each project to place a copy of the materialization's Python code in its `materializations/` directory.

If you use this approach, we strongly recommend storing the materialization code in a version-controlled repository and creating a reliable method of notifying users when it is updated.

### Python packaging

A more robust way to share custom materializations is to create and publish a Python package containing the implementation.

This is required when a Vulcan project uses Airflow or other external schedulers where the scheduler cluster doesn't have the `materializations/` folder available.

Package and expose custom materializations with the [setuptools entrypoints](https://packaging.python.org/en/latest/guides/creating-and-discovering-plugins/#using-package-metadata) mechanism:

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

Once the package is installed, Vulcan will automatically load custom materializations from the entrypoint list.

Refer to the Vulcan Github [custom_materializations](https://github.com/TobikoData/vulcan/tree/main/examples/custom_materializations) example for more details on Python packaging.
