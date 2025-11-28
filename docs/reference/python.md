# Python API

Vulcan is built in Python, and its complete Python API reference is located [here](https://vulcan.readthedocs.io/en/stable/_readthedocs/html/vulcan.html).

The Python API reference is comprehensive and includes the internal components of Vulcan. Those components are likely only of interest if you want to modify Vulcan itself.

If you want to use Vulcan via its Python API, the best approach is to study how the Vulcan [CLI](./cli.md) calls it behind the scenes. The CLI implementation code shows exactly which Python methods are called for each CLI command and can be viewed [on Github](https://github.com/TobikoData/vulcan/blob/main/vulcan/cli/main.py). For example, the Python code executed by the `plan` command is located [here](https://github.com/TobikoData/vulcan/blob/15c8788100fa1cfb8b0cc1879ccd1ad21dc3e679/vulcan/cli/main.py#L302).

Almost all the relevant Python methods are in the [Vulcan `Context` class](https://vulcan.readthedocs.io/en/stable/_readthedocs/html/vulcan/core/context.html#Context).
