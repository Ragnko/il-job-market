# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install packages
dbt deps

# Load reference data (european_countries.csv, exchange_rates.csv → raw dataset)
dbt seed

# Run all models
dbt run

# Run a single model (and its upstream dependencies)
dbt run --select +fact_compensation

# Run all tests
dbt test

# Run tests for a single model
dbt test --select mart_salary_by_region

# Full refresh of incremental models (reprocesses all history)
dbt run --full-refresh --select fact_compensation
dbt run --full-refresh --select fact_job_listings

# Compile SQL without executing (useful for syntax checks)
dbt compile

# Source freshness check
dbt source freshness

# Browse docs + lineage graph locally
dbt docs generate && dbt docs serve
```

**Python ingestion scripts** (require `gcloud auth application-default login`):

```bash
# Load SO survey (WRITE_TRUNCATE — replaces existing data)
python scripts/load_so_survey.py

# Scrape profesia.sk and append to raw.profesia_listings
python scripts/scrape_profesia.py                  # default: last 1 day, max 10 pages
python scripts/scrape_profesia.py --days 3 --max-pages 5
python scripts/scrape_profesia.py --dry-run        # print without uploading
```

**Required env var:** `export DBT_BQ_PROJECT=your-gcp-project-id`

---

## Architecture

Two independent data sources feed separate fact tables that share the same dimension tables and currency seed.

### Sources

| Source | Raw table | Ingestion |
|--------|-----------|-----------|
| Stack Overflow Developer Survey 2025 | `raw.so_survey` | `scripts/load_so_survey.py` (WRITE_TRUNCATE) |
| profesia.sk job listings | `raw.profesia_listings` | `scripts/scrape_profesia.py` (WRITE_APPEND) |

`load_so_survey.py` uses `pandas.read_csv(encoding='utf-8-sig')` instead of `bq load` because the SO CSV has a UTF-8 BOM, quoted column headers, and embedded newlines in free-text fields that break BigQuery's CSV parser.

`profesia_listings` is append-only — each scraper run adds rows with `_scraped_at`. Deduplication (keep latest scrape per `offer_id`) happens in `stg_profesia`.

### Layer responsibilities

**Staging** (`+schema: staging`, materialized as views)
- `stg_so_survey`: renames columns, casts types, filters implausible salaries (`$10k–$500k`), derives `experience_level_code` from `WorkExp`, normalises country names to match the seed.
- `stg_profesia`: deduplicates on `offer_id`, parses `salary_text` into `salary_eur_min/max`, detects remote listings, filters to IT jobs via the `is_it_job()` macro.

**Intermediate** (`+schema: intermediate`, materialized as views)
- `int_roles_classified`: inner-joins staging to `european_countries` seed (non-EU respondents are dropped here), applies `classify_role_family()` and `classify_seniority()` macros, drops rows where `role_family = 'Other'`.
- `int_salary_filtered`: computes per-country P1/P99 bounds as window functions, filters out respondents outside that range.

**Marts** (`+schema: marts`, materialized as tables unless noted)
- `fact_compensation` (incremental, merge on `response_id`): SO survey path — adds `comp_yearly_eur` via `exchange_rates` seed join on `work_year`. Watermark: `_bq_loaded_at`.
- `fact_job_listings` (incremental, merge on `listing_id`): profesia path — normalises hourly→monthly (×160 h), monthly→yearly (×12), converts EUR→USD. Watermark: `_scraped_at`.
- `dim_country`, `dim_role_family`, `dim_seniority`: static dimensions derived from seeds or intermediate models.
- `mart_salary_by_region`: pre-aggregated stats (median, P25/P75) by country × role × seniority; suppresses segments with `< 5 respondents`. **Primary BI table.**
- `mart_job_market_kpis`: pan-European weighted-average KPIs per role × seniority, plus `salary_spread_usd` (max − min country median).

### Macros

All classification logic lives in macros — changing them propagates to every model that calls them:

- `classify_role_family(col)`: LIKE-based pattern match on job title → 5 families (`Data Engineering`, `Data Analytics`, `Data Science`, `ML / AI Engineering`, `Database Administration`) or `Other`.
- `classify_seniority(col)`: maps experience codes `EN/MI/SE/EX` → `Junior/Mid/Senior/Staff / Lead`.
- `is_it_job(col)`: boolean filter for profesia listings — matches IT role keywords and Slovak equivalents (`programátor`, `vývojár`, etc.).

### Currency conversion

`seeds/exchange_rates.csv` holds yearly `eur_to_usd` and `usd_to_eur` rates. Both fact tables join to it on `work_year`. Add a new row here when extending to a new survey year.

### PII handling

`contact_name` (recruiter names from profesia.sk detail pages) is loaded raw into `raw.profesia_listings` and is noted as PII in `_sources.yml`. It is **not propagated beyond the raw layer** — `stg_profesia` and downstream models do not select it.

### Tests

Schema tests are defined in `_sources.yml`, `_stg_models.yml`, `_int_models.yml`, and `_mart_models.yml`. One custom singular test:
- `tests/assert_salary_within_country_band.sql`: fails if any segment in `mart_salary_by_region` has a median below `$15k USD`.

### CI (GitHub Actions)

Runs on every PR to `main`: `dbt deps` → `dbt compile` → `dbt seed` → `dbt test --select staging`. Requires `secrets.GCP_SA_KEY` and `vars.DBT_BQ_PROJECT`.
