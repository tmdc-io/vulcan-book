# Linter Configuration

Vulcan provides a linter that checks for potential issues in your models' code. Enable it and specify which linting rules to apply in the configuration file's `linter` key.

Rules are specified as lists of rule names under the `linter` key. Globally enable or disable linting with the `enabled` key, which is `false` by default.

**NOTE:** you **must** set the `enabled` key to `true` to apply the project's linting rules.

## Specific Linting Rules

This example specifies that the `"ambiguousorinvalidcolumn"` and `"invalidselectstarexpansion"` linting rules should be enforced:

=== "YAML"

    ```yaml linenums="1"
    linter:
      enabled: true
      rules: ["ambiguousorinvalidcolumn", "invalidselectstarexpansion"]
    ```

=== "Python"

    ```python linenums="1"
    from vulcan.core.config import Config, LinterConfig

    config = Config(
        linter=LinterConfig(
            enabled=True,
            rules=["ambiguousorinvalidcolumn", "invalidselectstarexpansion"]
        )
    )
    ```

## All Linting Rules

Apply every built-in and user-defined rule by specifying `"ALL"` instead of a list of rules:

=== "YAML"

    ```yaml linenums="1"
    linter:
      enabled: True
      rules: "ALL"
    ```

=== "Python"

    ```python linenums="1"
    from vulcan.core.config import Config, LinterConfig

    config = Config(
        linter=LinterConfig(
            enabled=True,
            rules="all",
        )
    )
    ```

## Ignoring Specific Rules

If you want to apply all rules except for a few, you can specify `"ALL"` and list the rules to ignore in the `ignored_rules` key:

=== "YAML"

    ```yaml linenums="1"
    linter:
      enabled: True
      rules: "ALL" # apply all built-in and user-defined rules and error if violated
      ignored_rules: ["noselectstar"] # but don't run the `noselectstar` rule
    ```

=== "Python"

    ```python linenums="1"
    from vulcan.core.config import Config, LinterConfig

    config = Config(
        linter=LinterConfig(
            enabled=True,
            # apply all built-in and user-defined linting rules and error if violated
            rules="all",
            # but don't run the `noselectstar` rule
            ignored_rules=["noselectstar"]
        )
    )
    ```

## Rule Violation Behavior

Linting rule violations raise an error by default, preventing the project from running until the violation is addressed.

You may specify that a rule's violation should not error and only log a warning by specifying it in the `warn_rules` key instead of the `rules` key.

=== "YAML"

    ```yaml linenums="1"
    linter:
      enabled: True
      # error if `ambiguousorinvalidcolumn` rule violated
      rules: ["ambiguousorinvalidcolumn"]
      # but only warn if "invalidselectstarexpansion" is violated
      warn_rules: ["invalidselectstarexpansion"]
    ```

=== "Python"

    ```python linenums="1"
    from vulcan.core.config import Config, LinterConfig

    config = Config(
        linter=LinterConfig(
            enabled=True,
            # error if `ambiguousorinvalidcolumn` rule violated
            rules=["ambiguousorinvalidcolumn"],
            # but only warn if "invalidselectstarexpansion" is violated
            warn_rules=["invalidselectstarexpansion"],
        )
    )
    ```

Vulcan will raise an error if the same rule is included in more than one of the `rules`, `warn_rules`, and `ignored_rules` keys since they should be mutually exclusive.

## Built-in Rules

Vulcan includes a set of predefined rules that check for potential SQL errors or enforce code style:

| Name                       | Check type  | Explanation                                                                                                              |
| -------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------ |
| `ambiguousorinvalidcolumn`  | Correctness | Vulcan found duplicate columns or was unable to determine whether a column is duplicated or not                         |
| `invalidselectstarexpansion` | Correctness | The query's top-level selection may be `SELECT *`, but only if Vulcan can expand the `SELECT *` into individual columns |
| `noselectstar`               | Stylistic   | The query's top-level selection may not be `SELECT *`, even if Vulcan can expand the `SELECT *` into individual columns |
| `nomissingaudits`             | Governance  | Vulcan did not find any `audits` in the model's configuration to test data quality.                                                 |

## Model-Level Configuration

You can specify that a specific *model* ignore a linting rule by specifying `ignored_rules` in its `MODEL` block.

This example specifies that the model `docs_example.full_model` should not run the `invalidselectstarexpansion` rule:

```sql linenums="1"
MODEL(
  name docs_example.full_model,
  ignored_rules ["invalidselectstarexpansion"] # or "ALL" to turn off linting completely
);
```

