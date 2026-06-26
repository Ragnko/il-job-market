"""
Scrape IT job listings from profesia.sk and load them into BigQuery.

Scrapes listing pages (title, company, location, salary) and for each listing
that exposes a contact name, fetches the detail page to capture it.

Raw contact_name is loaded as-is into raw.profesia_listings.
Hashing and masking happen downstream in dbt staging.

Usage:
    python scripts/scrape_profesia.py                   # last 1 day (default)
    python scripts/scrape_profesia.py --days 3          # last 3 days
    python scripts/scrape_profesia.py --max-pages 5     # limit pages scraped
    python scripts/scrape_profesia.py --dry-run         # print rows, no BQ upload
"""

import argparse
import re
import time
import logging
from datetime import datetime, timezone
from typing import Optional

import requests
from bs4 import BeautifulSoup
from google.cloud import bigquery

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)

BASE_URL    = "https://www.profesia.sk"
LISTING_URL = BASE_URL + "/praca/it-informacne-technologie/"
PROJECT     = "il-job-market"
TABLE       = f"{PROJECT}.raw.profesia_listings"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "sk-SK,sk;q=0.9,en;q=0.8",
}

# polite delay between requests
REQUEST_DELAY_S = 1.5


def get_soup(url: str, session: requests.Session) -> BeautifulSoup:
    resp = session.get(url, headers=HEADERS, timeout=15)
    resp.raise_for_status()
    time.sleep(REQUEST_DELAY_S)
    return BeautifulSoup(resp.text, "html.parser")


def parse_salary(card: BeautifulSoup) -> Optional[str]:
    label = card.select_one("span.label.label-bordered.green")
    if label:
        return label.get_text(separator=" ", strip=True)
    return None


def parse_listing_page(soup: BeautifulSoup) -> list[dict]:
    rows = soup.select("li.list-row")
    listings = []
    for row in rows:
        title_el   = row.select_one("span.title")
        company_el = row.select_one("span.employer")
        loc_el     = row.select_one("span.job-location")
        link_el    = row.select_one("h2 > a")
        posted_el  = row.select_one("span.info strong")
        id_el      = row.select_one("a.star[data-offer-id]")

        if not title_el or not link_el:
            continue

        offer_id = id_el["data-offer-id"] if id_el else None
        href     = link_el.get("href", "")
        # strip search_id query param — keep canonical URL
        url = BASE_URL + href.split("?")[0] if href else None

        listings.append({
            "offer_id":        offer_id,
            "title":           title_el.get_text(strip=True),
            "company":         company_el.get_text(strip=True) if company_el else None,
            "location":        loc_el.get_text(strip=True) if loc_el else None,
            "salary_text":     parse_salary(row),
            "posted_relative": posted_el.get_text(strip=True) if posted_el else None,
            "url":             url,
            "contact_name":    None,  # filled in by detail fetch if available
        })
    return listings


def fetch_contact_name(url: str, session: requests.Session) -> Optional[str]:
    """Fetch detail page and extract recruiter contact name if present."""
    try:
        soup = get_soup(url, session)
        # pattern: "Kontaktná osoba: Firstname Lastname"
        text = soup.get_text(separator=" ")
        match = re.search(r"Kontaktn[áa]\s+osoba\s*:\s*([^\n<]{2,60})", text)
        if match:
            # strip trailing noise like "Tel.: ..." or "E-mail: ..."
            name = re.split(r"\s+(Tel\.|E-mail:|Reagovať)", match.group(1))[0]
            return name.strip()
    except Exception as e:
        log.warning(f"Detail fetch failed for {url}: {e}")
    return None


def scrape(days: int, max_pages: int, session: requests.Session) -> list[dict]:
    all_listings: list[dict] = []
    page = 1

    while page <= max_pages:
        url = LISTING_URL + f"?count_days={days}&page_num={page}"
        log.info(f"Fetching listing page {page}: {url}")
        soup = get_soup(url, session)

        listings = parse_listing_page(soup)
        if not listings:
            log.info("No listings found on page — stopping.")
            break

        # fetch detail pages to capture contact names
        for listing in listings:
            if listing["url"]:
                log.info(f"  Detail: {listing['url']}")
                listing["contact_name"] = fetch_contact_name(listing["url"], session)

        all_listings.extend(listings)
        log.info(f"  Page {page}: {len(listings)} listings scraped")

        # check if next page exists — active li followed by another li with a link
        next_btn = soup.select_one("ul.pagination li.active + li a")
        if not next_btn:
            break
        page += 1

    return all_listings


def load_to_bigquery(rows: list[dict], scraped_at: datetime) -> None:
    scraped_at_str = scraped_at.isoformat()
    for row in rows:
        row["_scraped_at"] = scraped_at_str

    client = bigquery.Client(project=PROJECT)

    job_config = bigquery.LoadJobConfig(
        write_disposition="WRITE_APPEND",
        schema=[
            bigquery.SchemaField("offer_id",        "STRING"),
            bigquery.SchemaField("title",            "STRING"),
            bigquery.SchemaField("company",          "STRING"),
            bigquery.SchemaField("location",         "STRING"),
            bigquery.SchemaField("salary_text",      "STRING"),
            bigquery.SchemaField("posted_relative",  "STRING"),
            bigquery.SchemaField("url",              "STRING"),
            bigquery.SchemaField("contact_name",     "STRING"),
            bigquery.SchemaField("_scraped_at",      "TIMESTAMP"),
        ],
    )

    log.info(f"Loading {len(rows)} rows into {TABLE} ...")
    job = client.load_table_from_json(rows, TABLE, job_config=job_config)
    job.result()
    log.info(f"Done — {len(rows)} rows appended to {TABLE}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Scrape profesia.sk IT listings")
    parser.add_argument("--days",      type=int, default=1,   help="Listings from last N days (default: 1)")
    parser.add_argument("--max-pages", type=int, default=10,  help="Max listing pages to scrape (default: 10)")
    parser.add_argument("--dry-run",   action="store_true",   help="Print rows without uploading to BigQuery")
    args = parser.parse_args()

    scraped_at = datetime.now(timezone.utc)

    with requests.Session() as session:
        rows = scrape(days=args.days, max_pages=args.max_pages, session=session)

    log.info(f"Total listings scraped: {len(rows)}")

    if args.dry_run:
        for r in rows[:5]:
            print(r)
        print(f"... ({len(rows)} total rows, dry-run — not uploaded)")
        return

    if rows:
        load_to_bigquery(rows, scraped_at)
    else:
        log.warning("No rows scraped — nothing loaded.")


if __name__ == "__main__":
    main()
