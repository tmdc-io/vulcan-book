# Testing guide
## Testing changes to models
To run unit tests for your models, run the `vulcan test` command as follows:

```bash
$ vulcan test
.
----------------------------------------------------------------------
Ran 1 test in 0.042s

OK
```
As the unit tests run, Vulcan will identify any that fail.

For more information about tests, refer to [testing](../concepts/tests.md).

### Test changes to a specific model

To run a specific model test, pass in the suite file name followed by `::` and the name of the test; for example: `vulcan test tests/test_suite.yaml::test_example_full_model`.

### Run a subset of tests

To run a test that matches a pattern or substring, use the following syntax: `vulcan test tests/test_example*`.

Running the above command will run our `test_example_full_model` test that we ran earlier using `vulcan test`:

```
$ vulcan test tests/test_example*
.
----------------------------------------------------------------------
Ran 1 test in 0.042s

OK
```

As another example, running the `vulcan test tests/test_order*` command would run the following tests:

* `test_orders`
* `test_orders_takeout`
* `test_order_items`
* `test_order_type`

## Auditing changes to models
To audit your models, run the `vulcan audit` command as follows:

```bash
$ vulcan audit
Found 1 audit(s).
assert_positive_order_ids PASS.

Finished with 0 audit error(s).
Done.
```
**Note:** Ensure that you have already planned and applied your changes before running an audit.

By default, Vulcan will halt the pipeline when an audit fails in order to prevent potentially invalid data from propagating further downstream. All audits in Vulcan are blocking - when an audit fails, execution halts immediately.

For more information about audits, refer to [auditing](../concepts/audits.md).
