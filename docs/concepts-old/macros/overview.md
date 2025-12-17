# Overview

SQL is a [declarative language](https://en.wikipedia.org/wiki/Declarative_programming). It does not natively have features like variables or control flow logic (if-then, for loops) that allow SQL commands to behave differently in different situations.

However, data pipelines are dynamic and need different behavior depending on context. SQL is made dynamic with *macros*.

Vulcan supports two macro systems: Vulcan macros and the [Jinja](https://jinja.palletsprojects.com/en/3.1.x/) templating system.

Learn more about macros in Vulcan:

- [Pre-defined macro variables](../../components/advanced-features/macros/variables.md) available in both macro systems
- [Vulcan macros](../../components/advanced-features/macros/built_in.md)
- [Jinja macros](../../components/advanced-features/macros/jinja.md)
