# EU Developer Compensation — dbt Analytics Project

End-to-end analytics engineering project built on **Stack Overflow Developer Survey 2024**,
BigQuery, dbt Core, and Looker Studio.

**Core KPI:** Median annual compensation (USD) for data professionals across European
countries, segmented by role family and seniority tier.

---

## Architecture

```
SO Survey CSV
     │
     ▼
BigQuery raw.so_survey_2024          ← bq load (one-time)
     │
     ▼ dbt
staging.stg_survey_responses         ← view: rename, cast, basic filters
     │
     ▼
intermediate.int_roles_classified    ← view: Europe filter + role/seniority classification
intermediate.int_salary_filtered     ← view: country-level P1/P99 outlier removal
     │
     ▼
marts.dim_country                    ← table: EU countries seed
marts.dim_role_family                ← table: role taxonomy
marts.dim_seniority                  ← table: seniority tiers
marts.fact_compensation              ← INCREMENTAL table (merge on response_id)
     │
     ▼
marts.mart_salary_by_region          ← table: pre-aggregated by country/role/seniority
marts.mart_job_market_kpis           ← table: pan-European headline KPIs
     │
     ▼
Looker Studio dashboard              ← connects directly to mart_* tables
```

---

## Stack

| Layer          | Tool                        |
|----------------|-----------------------------|
| Warehouse      | Google BigQuery              |
| Transformation | dbt Core 1.8+               |
| BI             | Looker Studio               |
| CI/CD          | GitHub Actions              |
| Language       | SQL (BigQuery dialect)      |

---

## Setup

### 1. Prerequisites

```bash
# Python 3.11+ required
pip install -r requirements.txt

# GCP authentication
gcloud auth application-default login
```

### 2. Environment variable

```bash
export DBT_BQ_PROJECT=your-gcp-project-id
```

Add to `~/.zshrc` to persist.

### 3. BigQuery datasets

```bash
bq mk --dataset --location=EU ${DBT_BQ_PROJECT}:raw
bq mk --dataset --location=EU ${DBT_BQ_PROJECT}:dev
```

### 4. Download and load the survey data

Download from: https://survey.stackoverflow.co/2024/
(direct download, no account required — look for "Download Full Data Set")

```bash
# Unzip — gives you survey_results_public.csv (~65k rows)
unzip stack-overflow-developer-survey-2024.zip

# Load to BigQuery (autodetect schema)
bq load \
  --source_format=CSV \
  --autodetect \
  --skip_leading_rows=1 \
  ${DBT_BQ_PROJECT}:raw.so_survey_2024_raw \
  survey_results_public.csv

# Add the _bq_loaded_at timestamp column required for source freshness
bq query --use_legacy_sql=false "
  CREATE OR REPLACE TABLE \`${DBT_BQ_PROJECT}.raw.so_survey_2024\` AS
  SELECT *, CURRENT_TIMESTAMP() AS _bq_loaded_at
  FROM \`${DBT_BQ_PROJECT}.raw.so_survey_2024_raw\`
"
```

### 5. Run dbt

```bash
dbt deps                        # install dbt_utils package
dbt seed                        # load european_countries.csv to raw dataset
dbt run                         # build all models
dbt test                        # run all tests
dbt docs generate && dbt docs serve   # browse lineage + docs
```

Full refresh (rebuilds incremental model from scratch):

```bash
dbt run --full-refresh --select fact_compensation
```

---

## Key design decisions

**Incremental model (`fact_compensation`):** Uses `merge` strategy on `response_id`.
The watermark is `_bq_loaded_at` — for a live job-posting feed this would be
`posted_date`, allowing daily appends without reprocessing history.

**Outlier removal (`int_salary_filtered`):** Country-level P1/P99 bounds are computed
as window functions and applied as a filter. This preserves raw data integrity in staging
while keeping mart statistics clean.

**No business logic in the dashboard:** All aggregations (median, percentiles, weighted
averages) live in dbt marts. Looker Studio consumes pre-calculated fields only,
which keeps queries fast and the BI layer thin.

**Macro-driven classification:** `classify_seniority()` and `classify_role_family()`
are dbt macros — changing the classification bands in one file propagates everywhere.

---

## CI/CD

GitHub Actions runs on every pull request to `main`:
1. `dbt deps` — install packages
2. `dbt compile` — validate SQL syntax
3. `dbt seed` — load reference data
4. `dbt test --select staging` — run source + staging tests

Required GitHub secrets/vars:
- `secrets.GCP_SA_KEY` — service account JSON with BigQuery Data Editor + Job User roles
- `vars.DBT_BQ_PROJECT` — GCP project ID

---

## Looker Studio dashboard layout

Connect to: `{project}.dev_marts.mart_salary_by_region` (dev) or `{project}.prod_marts.mart_salary_by_region` (prod)

Suggested layout:
1. Scorecard — median salary for Data Engineers, Senior tier, all Europe
2. Bar chart — median salary by country (filterable by role_family + seniority_tier)
3. Heatmap table — country × role_family, coloured by median salary
4. Trend line — (if extended to multi-year data) salary by year
5. Filter controls — eu_region, role_family, seniority_tier, eu_member

---

## Prepared "what-if" extensions for the interview

- Add `remote_work` split: `RemoteWork` column is already in the source, add it to staging and fact
- Change KPI from median to salary range spread: already computed in `mart_job_market_kpis.salary_spread_usd`
- Add tech-stack filter (e.g. Python users only): `languages_used` is on the fact table, add a dashboard filter
- Extend to non-European countries: remove the `inner join european_countries` in `int_roles_classified`
