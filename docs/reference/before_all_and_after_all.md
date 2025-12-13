# Before_all and after_all Statements

The `before_all` and `after_all` statements are executed at the start and end, respectively, of the `vulcan plan` and `vulcan run` commands.

These statements can be defined in the configuration file under the `before_all` and `after_all` keys, either as a list of SQL statements or by using Vulcan macros:

=== "YAML"

    ```yaml linenums="1"
    before_all:
      - CREATE TABLE IF NOT EXISTS analytics (table VARCHAR, eval_time VARCHAR)
    after_all:
      - "@grant_select_privileges()"
      - "@IF(@this_env = 'prod', @grant_schema_usage())"
    ```

=== "Python"

    ```python linenums="1"
    from vulcan.core.config import Config

    config = Config(
        before_all = [
            "CREATE TABLE IF NOT EXISTS analytics (table VARCHAR, eval_time VARCHAR)"
        ],
        after_all = [
            "@grant_select_privileges()",
            "@IF(@this_env = 'prod', @grant_schema_usage())"
        ],
    )
    ```

## Examples

These statements allow for actions to be executed before all individual model statements or after all have run, respectively. They can also simplify tasks such as granting privileges.

### Example: Granting Select Privileges

For example, rather than using an `on_virtual_update` statement in each model to grant privileges on the views of the virtual layer, a single macro can be defined and used at the end of the plan:

```python linenums="1"
from vulcan.core.macros import macro

@macro()
def grant_select_privileges(evaluator):
    if evaluator.views:
        return [
            f"GRANT SELECT ON VIEW {view_name} /* sqlglot.meta replace=false */ TO ROLE admin_role;"
            for view_name in evaluator.views
        ]
```

By including the comment `/* sqlglot.meta replace=false */`, you further ensure that the evaluator does not replace the view name with the physical table name during rendering.

### Example: Granting Schema Privileges

Similarly, you can define a macro to grant schema usage privileges and, as demonstrated in the configuration above, using `this_env` macro conditionally execute it only in the production environment.

```python linenums="1"
from vulcan import macro

@macro()
def grant_schema_usage(evaluator):
    if evaluator.this_env == "prod" and evaluator.schemas:
        return [
            f"GRANT USAGE ON SCHEMA {schema} TO admin_role;"
            for schema in evaluator.schemas
        ]
```

As demonstrated in these examples, the `schemas` and `views` are available within the macro evaluator for macros invoked within the `before_all` and `after_all` statements. Additionally, the macro `this_env` provides access to the current environment name, which can be helpful for more advanced use cases that require fine-grained control over their behaviour.

