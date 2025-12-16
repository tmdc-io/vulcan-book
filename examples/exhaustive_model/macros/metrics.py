# macros/metrics.py
from sqlmesh import macro
from sqlglot import exp


@macro()
def safe_ratio(evaluator, num, den, default: float = 0.0):
    """Return a SQL expression that divides num/den with safe zero / null handling.
    Works across engines because it returns a SQLGlot expression tree.
    """
    # COALESCE to 0, then CASE WHEN to avoid division-by-zero at runtime
    num_e = exp.Coalesce(this=num, expressions=[exp.Literal.number(0)])
    den_e = exp.Coalesce(this=den, expressions=[exp.Literal.number(0)])
    return exp.Case(
    ifs=[exp.If(this=exp.EQ(this=den_e, expression=exp.Literal.number(0)), true=exp.Literal.number(default))],
    default=exp.Cast(this=exp.Div(this=num_e, expression=den_e), to=exp.DataType.build("DOUBLE"))
    )


@macro()
def label_top_n_category(evaluator, category_col, n: int = 5):
    """Return a CASE expression that keeps the top-N categories by total revenue in the current model scope
    and buckets the rest into 'Other'.
    NOTE: This macro is *semantic*; it produces SQL that re-aggregates by category and compares ranks at query time.
    """
    # Build a windowed RANK() over category by revenue
    # rank_col := RANK() OVER (ORDER BY SUM(revenue) DESC)
    # We can't reference outer SELECT aliases here, so expect callers to pass a numeric measure expression.
    # We'll inject a subquery frame: RANK() OVER (PARTITION BY 1 ORDER BY SUM(<measure>) DESC)
    measure = category_col.args.get("_measure") if hasattr(category_col, "args") else None
    # If users pass simple column ref for category, we'll just emit a CASE template that expects
    # a CTE with category + revenue alias to exist.
    # A portable approach: the calling query provides a CTE `cat_rank` (category, rnk)
    # For generality, we return a CASE that LEFT JOINs `cat_rank` via SQL clause operators in the model.
    # To keep this macro stand-alone, we instead emit CASE WHEN category IN (SELECT category FROM cat_rank WHERE rnk <= n) THEN category ELSE 'Other'
    n_lit = exp.Literal.number(n)  # Convert n to a SQL number literal
    return exp.Case(
        ifs=[
            exp.If(
                this=exp.In(
                    this=category_col,  # The category column to check
                    expressions=[
                        exp.Paren(
                            this=exp.Select()
                                .from_("cat_rank")  # Subquery from a CTE called "cat_rank"
                                .select("category")
                                .where(
                                    exp.LTE(
                                        this=exp.Column(this="rnk"),  # WHERE rnk <= n
                                        expression=n_lit
                                    )
                                )
                        )
                    ]
                ),
                true=category_col,  # If category is in top N, return the category
            )
        ],
        default=exp.Literal.string("Other")  # Otherwise, return "Other"
    )

