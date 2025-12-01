#

Vulcan is a complete stack for building data products.

Vulcan is a next-generation data transformation framework designed to ship data quickly, efficiently, and without error. Data teams can efficiently run and deploy data transformations written in SQL or Python with visibility and control at any size.

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
