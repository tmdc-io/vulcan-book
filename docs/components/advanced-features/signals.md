# Signals

Vulcan's [built-in scheduler](./scheduling.md#built-in-scheduler) is pretty smart—it knows when to run your models based on their `cron` schedules. If you have a model set to run `@daily`, it checks whether a day has passed since the last run and evaluates the model if needed.

But here's the thing: real-world data doesn't always follow our schedules. Sometimes data arrives late—maybe your upstream system had an issue, or a batch job ran behind schedule. When that happens, your daily model might have already run for the day, and that late data won't get processed until tomorrow's scheduled run.

Signals solve this problem by letting you add custom conditions that must be met before a model runs. Think of them as extra gates that the scheduler checks—beyond just "has enough time passed?" and "are upstream dependencies done?"

## What is a signal?

By default, Vulcan's scheduler uses two criteria to decide if a model should run:

1. Has the model's `cron` interval elapsed since the last evaluation?
2. Have all upstream dependencies finished running?

Signals let you add a third criterion: your own custom check. A signal is just a Python function that examines a batch of time intervals and decides whether they're ready for evaluation.

Here's how it works under the hood: The scheduler doesn't actually evaluate "a model"—it evaluates a model over specific time intervals. For incremental models, this is obvious (you're processing a date range). But even non-temporal models like `FULL` and `VIEW` are evaluated based on time intervals—their `cron` frequency determines the interval.

The scheduler looks at candidate intervals, groups them into batches (controlled by your model's `batch_size` parameter), and then checks signals to see if those batches are ready. Your signal function gets called with a batch of time intervals and can return:

- `True` if all intervals in the batch are ready
- `False` if none are ready
- A list of specific intervals if only some are ready

!!! note "One model, multiple signals"
    You can specify multiple signals for a single model. When you do, Vulcan requires that **all** signal functions agree an interval is ready before it gets evaluated. Think of it as an AND gate—every signal must give the green light.

## Defining a signal

To create a signal, add a `signals` directory to your project and create your signal function in `__init__.py` (you can organize signals across multiple Python files if you prefer).

A signal function needs to:
- Accept a batch of time intervals (`DateTimeRanges: t.List[t.Tuple[datetime, datetime]]`)
- Return either a boolean or a list of intervals
- Use the `@signal` decorator

Let's look at some examples, starting simple and building up to more complex use cases.

### Simple example

Here's a basic signal that randomly decides whether intervals are ready (useful for testing, maybe not so much for production!):

```python linenums="1"
import random
import typing as t
from vulcan import signal, DatetimeRanges


@signal()
def random_signal(batch: DatetimeRanges, threshold: float) -> t.Union[bool, DatetimeRanges]:
    return random.random() > threshold
```

This signal takes a `threshold` argument (you'll pass this from your model definition) and returns `True` if a random number exceeds that threshold. Notice how the function signature includes `threshold: float`—Vulcan will automatically extract this from your model definition and pass it to the function. The type inference works the same way as [Vulcan macros](../concepts/macros/vulcan_macros.md#typed-macros).

To use this signal in a model, add it to the `signals` key in your `MODEL` block:

```sql linenums="1" hl_lines="4-6"
MODEL (
  name example.signal_model,
  kind FULL,
  signals (
    random_signal(threshold := 0.5), # specify threshold value
  )
);

SELECT 1
```

The `signals` key accepts a list of signal calls, each with its own arguments. When you run `vulcan run`, this signal will essentially flip a coin—if the random number is greater than 0.5, the model runs; otherwise, it waits.

### Advanced example

Sometimes you want more fine-grained control. Instead of saying "all intervals are ready" or "none are ready," you can return specific intervals from the batch. Here's an example that only allows intervals from at least one week ago:

```python
import typing as t

from vulcan import signal, DatetimeRanges
from vulcan.utils.date import to_datetime


# signal that returns only intervals that are <= 1 week ago
@signal()
def one_week_ago(batch: DatetimeRanges) -> t.Union[bool, DatetimeRanges]:
    dt = to_datetime("1 week ago")

    return [
        (start, end)
        for start, end in batch
        if start <= dt
    ]
```

Instead of returning `True` or `False` for the entire batch, this function filters the batch and returns only the intervals that meet the criteria. It compares each interval's start time to "1 week ago" and includes only those that are old enough.

Use it in an incremental model like this:

```sql linenums="1" hl_lines="7-10"
MODEL (
  name example.signal_model,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column ds,
  ),
  start '2 week ago',
  signals (
    one_week_ago(),
  )
);

SELECT @start_ds AS ds
```

This ensures that only data from at least a week ago gets processed—useful if you want to wait for late-arriving data to stabilize before processing it.

### Accessing execution context

Sometimes you need to check something in your database or access the execution context. You can do that by adding a `context` parameter to your signal function:

```python
import typing as t

from vulcan import signal, DatetimeRanges, ExecutionContext


# add the context argument to your function
@signal()
def one_week_ago(batch: DatetimeRanges, context: ExecutionContext) -> t.Union[bool, DatetimeRanges]:
    return len(context.engine_adapter.fetchdf("SELECT 1")) > 1
```

The `context` parameter gives you access to the engine adapter, so you can query your warehouse, check if certain tables exist, verify data freshness, or perform any other checks you need.

### Testing signals

Signals only evaluate when you run `vulcan run` or use the `check_intervals` command. To test your signals without actually running models:

1. Deploy your changes to an environment: `vulcan plan my_dev`
2. Check which intervals would be evaluated: `vulcan check_intervals my_dev`
   - Use `--select-model` to check specific models
   - Use `--no-signals` to see what would run without signal checks
3. Iterate by making changes to your signal and redeploying

!!! note
    The `check_intervals` command only works with remote models that have been deployed to an environment. Local signal changes won't be tested until you deploy them.

This workflow lets you verify your signal logic before it affects your actual model runs.
