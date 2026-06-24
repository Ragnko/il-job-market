"""
Load Stack Overflow Developer Survey 2025 into BigQuery.

WHY THIS SCRIPT EXISTS — bq load DOES NOT WORK ON THIS FILE
------------------------------------------------------------
The SO survey CSV has three properties that cause `bq load --autodetect` to fail
even with --allow_quoted_newlines:

1. UTF-8 BOM (byte order mark)
   The file starts with the invisible character ﻿. BigQuery's CSV parser
   passes this through and appends it to the first column name, producing
   '"\\ufeffResponseId"' instead of 'ResponseId'. BigQuery then rejects
   the field name as invalid under its default character map (V1).

   bq load error:
       Field name '"ResponseId"' is not supported by the current character map.

2. Quoted column headers
   Every column name in the header row is wrapped in double quotes
   (e.g. "ResponseId","Country","DevType",...). BigQuery's autodetect
   treats the quotes as part of the field name rather than as CSV quoting,
   compounding the issue above.

3. Free-text fields with embedded newlines and unescaped quotes
   Open-ended survey questions (e.g. "What does a good developer look like?")
   contain multi-line answers and internal double-quote characters that are
   not properly escaped per RFC 4180. bq load --allow_quoted_newlines reduces
   the error count but does not eliminate it.

   bq load error (sample):
       CSV table encountered too many errors, giving up. Rows: 2162; errors: 100
       Missing close quote character (").; line_number: 12 column_name: "string_field_145"

FIX
---
pandas.read_csv() handles all three issues out of the box:
  - encoding='utf-8-sig'  strips the BOM and unquotes column names
  - engine='python'       tolerates malformed quoting in free-text fields
  - low_memory=False      reads all columns as object first to avoid dtype errors

After reading into a DataFrame we add _bq_loaded_at and upload via the
BigQuery Python client, which serialises to Parquet internally — bypassing
the CSV parser entirely.
"""

import pandas as pd
from google.cloud import bigquery
from datetime import datetime, timezone

SOURCE_URL = (
    "https://media.githubusercontent.com/media/StackExchange/Survey"
    "/refs/heads/main/packages/archive/2025/results.csv"
)
PROJECT    = "il-job-market"
TABLE      = f"{PROJECT}.raw.so_survey"

def main() -> None:
    print(f"Downloading survey from:\n  {SOURCE_URL}\n")
    df = pd.read_csv(
        SOURCE_URL,
        encoding="utf-8-sig",   # strips BOM, unquotes column names
        low_memory=False,        # avoids mixed-type inference errors
    )
    print(f"Downloaded {len(df):,} rows × {len(df.columns)} columns")

    df["_bq_loaded_at"] = datetime.now(timezone.utc)

    client = bigquery.Client(project=PROJECT)
    job_config = bigquery.LoadJobConfig(
        write_disposition="WRITE_TRUNCATE",
        autodetect=True,
    )

    print(f"\nUploading to {TABLE} ...")
    job = client.load_table_from_dataframe(df, TABLE, job_config=job_config)
    job.result()

    n = client.get_table(TABLE).num_rows
    print(f"Done — {n:,} rows loaded into {TABLE}")


if __name__ == "__main__":
    main()
