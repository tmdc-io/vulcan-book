# Vulcan Documentation Structure

## Design Philosophy

**Progressive Disclosure**: Begin with fundamentals and build toward complexity. Each chapter stands alone while contributing to a coherent whole.

**Hands-On Learning**: Every concept includes executable code. Theory is paired with practice throughout.

**Clear Distinctions**: Separate similar concepts explicitly. Audits are not checks. Models are not semantics. Tests are not validations.

**Vulcan-Specific Focus**: Emphasize what makes Vulcan unique. Reference SQLMesh foundation without duplicating upstream documentation.

## Learning Path

```
Foundation (Chapters 1-2)
    ↓
Core Features (Chapters 3-6)
    ↓
Operations (Chapter 7)
```

---

## Chapter Overview

### 1. Getting Started
**Audience**: New users, evaluators  
**Goal**: Productive in 30 minutes

```
01-getting-started/
├── index.md              # What is Vulcan? Why Vulcan?
├── installation.md       # Install + quickstart
├── your-first-project.md # 5-minute tutorial
├── core-concepts.md      # SQLMesh foundation
└── integrations.md       # DuckDB, Postgres, Snowflake, BigQuery, Databricks
                          # dbt migration guide
```

### 2. Models
**Audience**: Data engineers  
**Goal**: Master model development and testing

```
02-models/
├── index.md              # Model basics
├── sql-models.md         # SQL model syntax
├── python-models.md      # Python models
├── model-kinds.md        # FULL, INCREMENTAL, SCD_TYPE_2
├── unit-tests.md         # Model unit tests, CI/CD integration
├── audits-reference.md   # Cross-reference to Chapter 4
└── best-practices.md     # Naming, organization, performance
```

**Cross-Reference**: Links to Chapter 4 for data validation.

### 3. Semantic Layer (Vulcan-Specific)
**Audience**: Analytics engineers, BI developers  
**Goal**: Define business semantics on physical models

```
03-semantic-layer/
├── index.md                 # Why semantic layer? Overview
├── models-and-aliases.md    # Physical tables to semantic models
├── dimensions.md            # Column selection, overrides, tags
├── measures.md              # Aggregations, expressions, filters
├── segments.md              # Filter conditions, dimension proxies
├── joins.md                 # Cross-model relationships
├── business-metrics.md      # Time-series metrics
├── validation.md            # Auto-validation, troubleshooting
├── export-schemas.md        # Generic schema export (no BI tool coupling)
└── yaml-reference.md        # Complete YAML specification
```

### 4. Audits (Vulcan-Specific)
**Audience**: Data engineers  
**Goal**: Comprehensive data validation strategy

```
04-audits/
├── 01-introduction.md         # What are audits?
│                              # AUDIT vs ASSERTION terminology
│                              # Audits vs Checks vs Profiles comparison
│                              # Audits vs OLTP constraints
│                              # When to use audits
│
├── 02-quick-start.md          # First audit, common patterns
│
├── 03-builtin-audits.md       # All 29 built-in audits
│                              # Categories: Completeness, Uniqueness, Validity
│                              # String, Pattern, Statistical, Generic
│
├── 04-custom-audits.md        # File-based audits
│                              # Parameterization, macros
│                              # Dialect-specific audits
│
├── 05-inline-audits.md        # Inline patterns
│                              # When to use inline vs file-based
│
├── 06-advanced-patterns.md    # Complex validation
│                              # Referential integrity
│                              # Time-based validation
│                              # Statistical outliers
│                              # Hierarchical data
│
├── 07-execution-lifecycle.md  # CRITICAL: When audits run
│                              # Plan vs Run modes
│                              # Virtual environments vs direct writes
│                              # Incremental vs full refresh scope
│                              # Performance optimization
│
├── 08-troubleshooting.md      # Debugging failed audits
│
├── 09-best-practices.md       # Production strategies
│                              # Coverage strategy
│                              # Performance tuning
│
└── 10-quick-reference.md      # Cheat sheets, decision trees
```

**Length**: Approximately 4,500 lines  
**Design**: Single comprehensive chapter. Removed section summaries for better flow.  
**Key Section**: Chapter 7 (execution lifecycle) explains plan vs run modes.

**Cross-Reference**: Referenced from Chapter 2 (Models). Compared with Chapter 5 (Quality Checks).

### 5. Quality Checks
**Audience**: Data quality engineers  
**Goal**: Monitoring and profiling with Soda

```
05-quality-checks/
├── index.md                 # What are quality checks?
│                            # Checks vs Audits distinction
│
├── check-configuration.md   # checks.yml, SodaCL syntax
├── builtin-checks.md        # Soda built-in checks
├── custom-checks.md         # Custom check patterns
├── running-checks.md        # Execution strategies
├── check-results-api.md     # Querying results
├── profiles.md              # Statistical profiling
│                            # Profile configuration
│                            # Using profiles to inform audits
│
└── troubleshooting.md       # Common issues
```

**Cross-Reference**: Clear distinction from Chapter 4 (Audits) throughout.

### 6. APIs (Vulcan-Specific)
**Audience**: Developers, operations teams  
**Goal**: Complete API reference

```
06-apis/
├── index.md                     # API overview
│                                # REST, Python, CLI
│
├── activity-tracking/
│   ├── overview.md              # Activity tracking concepts
│   ├── run-executions.md        # GET /runs
│   ├── model-activity.md        # GET /models/{id}/runs
│   └── environment-management.md # Environment tracking
│
├── meta-graph/
│   ├── overview.md              # Graph database (KuzuDB)
│   ├── querying-lineage.md      # Cypher queries
│   ├── impact-analysis.md       # Downstream impact
│   ├── semantic-exploration.md  # Discovering metrics
│   └── query-cookbook.md        # Query patterns
│
├── python-api.md                # VulcanContext reference
├── rest-api.md                  # HTTP endpoints
├── cli-reference.md             # CLI commands
└── configuration-reference.md   # config.yaml specification
```

**Design**: Consolidates Activity Tracking, Meta Graph, and API Reference for cohesion.

### 7. Deployment
**Audience**: DevOps, platform engineers  
**Goal**: Production deployment strategies

```
07-deployment/
├── index.md              # Deployment strategies
├── plan-and-apply.md     # SQLMesh workflow
├── environments.md       # Dev, staging, prod
├── scheduling.md         # Airflow, cron, orchestration
└── monitoring.md         # Observability, alerting
```

**Status**: To be determined.

---

## Cross-Reference Map

**Chapter 2 (Models) → Chapter 4 (Audits)**  
Models chapter includes audits-reference.md with quick examples and link to comprehensive guide.

**Chapter 4 (Audits) ↔ Chapter 5 (Quality Checks)**  
Both chapters include comparison tables distinguishing blocking validation from monitoring.

**Chapter 3 (Semantic Layer) ← Chapter 6 (APIs)**  
Meta graph APIs query semantic layer. Python API provides semantic layer access.

**Chapter 1 (Getting Started) → All Chapters**  
Core concepts link to detailed chapters for Models, Semantics, Audits.

---

## Implementation Notes

**Chapter Length Management**:
- Chapter 1: Short (500 lines) - fast start
- Chapter 2: Medium (1,500 lines) - foundation
- Chapter 3: Long (2,000 lines) - complex domain
- Chapter 4: Very Long (4,500 lines) - comprehensive reference
- Chapter 5: Medium (1,200 lines) - focused scope
- Chapter 6: Long (1,800 lines) - consolidated APIs
- Chapter 7: To be determined

**For Long Chapters**:
- Clear section numbering
- Comprehensive table of contents with anchors
- Quick reference sections
- Self-contained subsections

**Documentation Standards**:
- Every concept includes executable code
- No theory-only sections
- Copy-paste ready examples
- Real-world scenarios
