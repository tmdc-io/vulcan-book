# Linter

Linting is like having a code reviewer that never gets tired. It automatically checks your model definitions to make sure they follow your team's best practices and catches common mistakes before they cause problems.

When you create a Vulcan plan, each model's code gets checked against the linting rules you've configured. If any rules are violated, Vulcan will let you know so you can fix the issues before deploying.

Vulcan comes with several built-in rules that catch common SQL mistakes and enforce good practices. But you're not limited to those, you can also write custom rules that match your team's specific requirements. This helps maintain code quality and catches issues early, when they're much easier to fix.

## Rules

Linting rules are basically pattern detectors. Each rule looks for a specific pattern (or lack of a pattern) in your model code.

Some rules check that a pattern *isn't* present, like the `NoSelectStar` rule that prevents `SELECT *` in your outermost query. Other rules check that a pattern *is* present, like making sure every model has an `owner` field specified. Both types help keep your code consistent and maintainable.

Rules are written in Python, which makes them flexible and powerful. Each rule is a Python class that inherits from Vulcan's `Rule` base class. You define the logic for detecting the pattern, and Vulcan handles the rest.

Here's how the `Rule` base class works (you can see the [full source code](https://github.com/TobikoData/vulcan/blob/main/vulcan/core/linter/rule.py) if you want all the details). When you create a custom rule, you'll need to implement four things:

1. **Name** - The class name becomes the rule's name (converted to lowercase with underscores).
2. **Description** - A docstring that explains what the rule checks and why it matters.
3. **Pattern validation logic** - The `check_model()` method that actually checks your model code. You can access any attribute of the `Model` object to make your decision.
4. **Rule violation logic** - If the pattern isn't valid, return a `RuleViolation` object with a helpful message that tells the user what's wrong and how to fix it.

``` python linenums="1"
# Class name used as rule's name
class Rule:
    # Docstring provides rule's description
    """The base class for a rule."""

    # Pattern validation logic goes in `check_model()` method
    @abc.abstractmethod
    def check_model(self, model: Model) -> t.Optional[RuleViolation]:
        """The evaluation function that checks for a violation of this rule."""

    # Rule violation object returned by `violation()` method
    def violation(self, violation_msg: t.Optional[str] = None) -> RuleViolation:
        """Return a RuleViolation instance if this rule is violated"""
        return RuleViolation(rule=self, violation_msg=violation_msg or self.summary)
```

### Built-in rules

Vulcan comes with several built-in rules that catch common SQL mistakes and enforce good coding practices. These are battle-tested rules that catch real issues we've seen in production.

For example, the `NoSelectStar` rule prevents you from using `SELECT *` in your outermost query. Why? Because `SELECT *` makes it unclear what columns your model actually produces, which can break downstream models and make debugging harder.

Here's what the `NoSelectStar` rule looks like, with annotations showing how it's structured:

``` python linenums="1"
# Rule's name is the class name `NoSelectStar`
class NoSelectStar(Rule):
    # Docstring explaining rule
    """Query should not contain SELECT * on its outer most projections, even if it can be expanded."""

    def check_model(self, model: Model) -> t.Optional[RuleViolation]:
        # If this model does not contain a SQL query, there is nothing to validate
        if not isinstance(model, SqlModel):
            return None

        # Use the query's `is_star` property to detect the `SELECT *` pattern.
        # If present, call the `violation()` method to return a `RuleViolation` object.
        return self.violation() if model.query.is_star else None
```

Here are all of Vulcan's built-in linting rules:

| Name                       | Check type  | Explanation                                                                                                              |
| -------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------ |
| `ambiguousorinvalidcolumn`  | Correctness | Vulcan found duplicate columns or was unable to determine whether a column is duplicated or not                         |
| `invalidselectstarexpansion` | Correctness | The query's top-level selection may be `SELECT *`, but only if Vulcan can expand the `SELECT *` into individual columns |
| `noselectstar`               | Stylistic   | The query's top-level selection may not be `SELECT *`, even if Vulcan can expand the `SELECT *` into individual columns |
| `nomissingaudits`             | Governance  | Vulcan did not find any `audits` in the model's configuration to test data quality.                                                 |

### User-defined rules

Built-in rules are great, but every team has different standards. That's where custom rules come in. You can write rules that enforce your team's specific best practices.

For example, maybe you want to make sure every model has an `owner` field so you know who's responsible for it. Here's how you'd write that rule:

``` python linenums="1" title="linter/user.py"
import typing as t

from vulcan.core.linter.rule import Rule, RuleViolation
from vulcan.core.model import Model

class NoMissingOwner(Rule):
    """Model owner should always be specified."""

    def check_model(self, model: Model) -> t.Optional[RuleViolation]:
        # Rule violated if the model's owner field (`model.owner`) is not specified
        return self.violation() if not model.owner else None

```

Put your custom rules in the `linter/` directory of your project. Vulcan will automatically find and load any classes that inherit from `Rule` in that directory.

Once you've added a rule to your [configuration file](#applying-linting-rules), Vulcan will run it automatically when:
- You create a plan with `vulcan plan`
- You run the `vulcan lint` command

If a model violates a rule, Vulcan will stop and tell you exactly which model(s) have problems. Here's what that looks like, in this example, `full_model.sql` is missing an owner, so the plan stops:

``` bash
$ vulcan plan

Linter errors for .../models/full_model.sql:
 - nomissingowner: Model owner should always be specified.

Error: Linter detected errors in the code. Please fix them before proceeding.
```

You can also run linting on its own for faster iteration during development:

``` bash
$ vulcan lint

Linter errors for .../models/full_model.sql:
 - nomissingowner: Model owner should always be specified.

Error: Linter detected errors in the code. Please fix them before proceeding.
```

Use `vulcan lint --help` for more information.


## Applying linting rules

Specify which linting rules a project should apply in the project's [configuration file](../overview.md).

You specify which rules to run as a list under the `linter` key. You can also globally enable or disable linting with the `enabled` key (it defaults to `false`, so you'll need to turn it on).

!!! important
    **Don't forget to set `enabled: true`!** If you don't, Vulcan won't run any linting rules, even if you've specified them.

### Specific linting rules

Want to use just a few specific rules? No problem. Just list them in the `rules` array. Here's an example that enables two built-in rules:

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

### All linting rules

Want to enable all the rules? Just use `"ALL"` instead of listing them individually. This will run every built-in rule plus any custom rules you've defined:

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

Sometimes you want almost everything, but there's one or two rules that don't fit your workflow. You can use `"ALL"` and then exclude specific rules with `ignored_rules`:

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

### Exclude a model from linting

Sometimes you have a model that legitimately needs to violate a rule. Maybe it's a legacy model you're migrating, or there's a special case. You can exclude specific models from specific rules (or all rules) by adding `ignored_rules` to the model's `MODEL` block.

Here's an example where we exclude one model from one rule:

```sql linenums="1"
MODEL(
  name docs_example.full_model,
  ignored_rules ["invalidselectstarexpansion"] # or "ALL" to turn off linting completely
);
```

### Rule violation behavior

By default, when a rule is violated, Vulcan treats it as an error and stops execution. This ensures you fix issues before they make it to production.

But sometimes you want a rule to be more of a suggestion than a hard requirement. Maybe it's a style preference that's nice to have but not critical. In that case, you can put the rule in `warn_rules` instead of `rules`. Violations will still be reported, but they won't stop execution:

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