#

Vulcan is a complete stack for building data products.

Vulcan is a next-generation data transformation framework designed to ship data quickly, efficiently, and without error. Data teams can efficiently run and deploy data transformations written in SQL or Python with visibility and control at any size.

> Architecture Diagram

> Get instant SQL impact analysis of your changes, whether in the CLI or in Vulcan Plan Mode

??? tip "Virtual Data Environments"

    - See a full diagram of how [Virtual Data Environments](https://whimsical.com/virtual-data-environments-MCT8ngSxFHict4wiL48ymz) work
    - [Watch this video to learn more](https://www.youtube.com/watch?v=weJH3eM0rzc)

* Create isolated development environments without data warehouse costs
* Plan / Apply workflow like [Terraform](https://www.terraform.io/) to understand potential impact of changes
* Easy to use CI/CD workflows for true blue-green deployments

??? tip "Efficiency and Testing"

    Running this command will generate a unit test file in the `tests/` folder: `test_stg_payments.yaml`

    Runs a live query to generate the expected output of the model

    ```bash
    vulcan create_test tcloud_demo.stg_payments --query tcloud_demo.seed_raw_payments "select * from tcloud_demo.seed_raw_payments limit 5"

    # run the unit test
    vulcan test
    ```

    ```sql
    MODEL (
      name tcloud_demo.stg_payments,
      cron '@daily',
      grain payment_id,
      audits (UNIQUE_VALUES(columns = (
          payment_id
      )), NOT_NULL(columns = (
          payment_id
      )))
    );

    SELECT
        id AS payment_id,
        order_id,
        payment_method,
        amount / 100 AS amount, /* `amount` is currently stored in cents, so we convert it to dollars */
        'new_column' AS new_column, /* non-breaking change example  */
    FROM tcloud_demo.seed_raw_payments
    ```

    ```yaml
    test_stg_payments:
    model: tcloud_demo.stg_payments
    inputs:
        tcloud_demo.seed_raw_payments:
          - id: 66
            order_id: 58
            payment_method: coupon
            amount: 1800
          - id: 27
            order_id: 24
            payment_method: coupon
            amount: 2600
          - id: 30
            order_id: 25
            payment_method: coupon
            amount: 1600
          - id: 109
            order_id: 95
            payment_method: coupon
            amount: 2400
          - id: 3
            order_id: 3
            payment_method: coupon
            amount: 100
    outputs:
        query:
          - payment_id: 66
            order_id: 58
            payment_method: coupon
            amount: 18.0
            new_column: new_column
          - payment_id: 27
            order_id: 24
            payment_method: coupon
            amount: 26.0
            new_column: new_column
          - payment_id: 30
            order_id: 25
            payment_method: coupon
            amount: 16.0
            new_column: new_column
          - payment_id: 109
            order_id: 95
            payment_method: coupon
            amount: 24.0
            new_column: new_column
          - payment_id: 3
            order_id: 3
            payment_method: coupon
            amount: 1.0
            new_column: new_column
    ```

* Never build a table [more than once](https://tobikodata.com/simplicity-or-efficiency-how-dbt-makes-you-choose.html)
* Track what data's been modified and run only the necessary transformations for [incremental models](https://tobikodata.com/correctly-loading-incremental-data-at-scale.html)
* Run [unit tests](https://tobikodata.com/we-need-even-greater-expectations.html) for free and configure automated audits

??? tip "Level Up Your SQL"

    Write SQL in any dialect and Vulcan will transpile it to your target SQL dialect on the fly before sending it to the warehouse.
    <img src="assets/images/transpile_example.png" alt="Transpile Example">

* Debug transformation errors *before* you run them in your warehouse in 10+ different SQL dialects
* Definitions using [simply SQL](concepts/models/sql_models.md#sql-based-definition) (no need for redundant and confusing `Jinja` + `YAML`)
* See impact of changes before you run them in your warehouse with column-level lineage

For more information, check out the [documentation](https://tmdc-io.github.io/vulcan-book).

## Getting Started
Install Vulcan through [pypi](https://pypi.org/project/vulcan/) by running:

```bash
mkdir vulcan-example
cd vulcan-example
python -m venv .venv
source .venv/bin/activate
pip install vulcan
source .venv/bin/activate # reactivate the venv to ensure you're using the right installation
vulcan init duckdb # get started right away with a local duckdb instance
vulcan plan # see the plan for the changes you're making
```

> Note: You may need to run `python3` or `pip3` instead of `python` or `pip`, depending on your python installation.

Follow the [quickstart guide](getting_started/docker.md) to learn how to use Vulcan. You already have a head start!
