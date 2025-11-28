# Overview

Realistic examples are a fantastic way to understand Vulcan better.

They allow you to tinker with a project's code and data, issuing different Vulcan commands to see what happens.

You can reset the examples at any time, so if things get turned around you can just start over!

This page links to a few different types of examples:

- **Walkthroughs** pose a specific story or task, and you follow along as we work through the story
    - Walkthroughs **do not** require running code, although the code is available if you would like to
    - Different walkthroughs use different SQL engines, so if you want to run the code you might need to update it for your SQL engine
- **Projects** are self-contained Vulcan projects and datasets
    - Projects generally use DuckDB so you can run them locally without installing or accessing a separate SQL engine

!!! tip

    If you haven't tried out Vulcan before, we recommending working through the [Vulcan Quickstart](../quick_start.md) before trying these examples!

## Walkthroughs

Walkthroughs are easy to follow and provide lots of information in a self-contained format.

- Get the Vulcan workflow under your fingers with the [Vulcan CLI Crash Course](./vulcan_cli_crash_course.md)
- See the end-to-end workflow in action with the [Incremental by Time Range: Full Walkthrough](./incremental_time_full_walkthrough.md) (BigQuery SQL engine)

## Projects

Vulcan example projects are stored in the [vulcan-examples Github repository](https://github.com/TobikoData/vulcan-examples). The repository's front page includes additional information about how to download the files and set up the projects.

The two most comprehensive example projects use the Vulcan `sushi` data, based on a fictional sushi restaurant. ("Tobiko" is the Japanese word for flying fish roe, commonly used in sushi.)

The `sushi` data is described in an [overview notebook](https://github.com/TobikoData/vulcan-examples/blob/main/001_sushi/sushi-overview.ipynb) in the repository.

The example repository include two versions of the `sushi` project, at different levels of complexity:

- The [`simple` project](https://github.com/TobikoData/vulcan-examples/tree/main/001_sushi/1_simple) contains four `VIEW` and one `SEED` model
    - The `VIEW` model kind refreshes every run, making it easy to reason about Vulcan's behavior
- The [`moderate` project](https://github.com/TobikoData/vulcan-examples/tree/main/001_sushi/2_moderate) contains five `INCREMENTAL_BY_TIME_RANGE`, one `FULL`, one `VIEW`, and one `SEED` model
    - The incremental models allow you to observe how and when new data is transformed by Vulcan
    - Some models, like `customer_revenue_lifetime`, demonstrate more advanced incremental queries like customer lifetime value calculation
