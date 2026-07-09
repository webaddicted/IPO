"""On-demand scrape orchestration — list, subscription, details, GMP."""

from __future__ import annotations

import logging
import time

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.db.models import CompanyProfile, Ipo, SubscriptionSnapshot
from app.scrapers.factory import build_scrapers

log = logging.getLogger(__name__)

MAX_ATTEMPTS = 3


class ScrapeIncompleteError(Exception):
    def __init__(self, issues: list[str], counts: dict[str, int]) -> None:
        super().__init__("; ".join(issues))
        self.issues = issues
        self.counts = counts


def validate_scrape(db: Session, counts: dict[str, int]) -> list[str]:
    """Return list of validation issues; empty means all data stored."""
    issues: list[str] = []
    ipo_total = db.scalar(select(func.count()).select_from(Ipo)) or 0
    company_total = db.scalar(select(func.count()).select_from(CompanyProfile)) or 0
    sub_total = db.scalar(
        select(func.count())
        .select_from(SubscriptionSnapshot)
        .where(SubscriptionSnapshot.bucket == "overall")
    ) or 0
    scraped_total = db.scalar(
        select(func.count()).select_from(Ipo).where(Ipo.last_scraped_at.is_not(None))
    ) or 0

    if counts.get("listUpserted", 0) <= 0:
        issues.append("IPO list scrape returned 0 rows")
    if ipo_total == 0:
        issues.append("No IPOs in database")
    if company_total < ipo_total:
        issues.append(f"ipo_company_profiles {company_total}/{ipo_total}")
    if sub_total < ipo_total:
        issues.append(f"ipo_subscription_snapshots {sub_total}/{ipo_total}")
    if scraped_total < ipo_total:
        issues.append(f"details scraped {scraped_total}/{ipo_total}")
    if counts.get("detailsUpdated", 0) < ipo_total:
        issues.append(f"detail pass count {counts.get('detailsUpdated', 0)}/{ipo_total}")

    return issues


def run_scrape(db: Session) -> dict[str, int]:
    """Scrape chittorgarh.com + investorgain; retry until validation passes."""
    last_counts: dict[str, int] = {}
    last_issues: list[str] = []

    for attempt in range(1, MAX_ATTEMPTS + 1):
        log.info("Scrape attempt %s/%s", attempt, MAX_ATTEMPTS)
        last_counts = _run_once(db, attempt)
        last_issues = validate_scrape(db, last_counts)
        if not last_issues:
            summary = (
                f"Scrape SUCCESS — "
                f"list={last_counts['listUpserted']}, "
                f"subscription={last_counts['subscriptionUpdated']}, "
                f"details={last_counts['detailsUpdated']}, "
                f"gmp={last_counts['gmpUpdated']}"
            )
            print(summary, flush=True)
            log.info(summary)
            return last_counts

        log.warning("Scrape validation failed: %s", "; ".join(last_issues))
        if attempt < MAX_ATTEMPTS:
            time.sleep(2 * attempt)

    raise ScrapeIncompleteError(last_issues, last_counts)


def _run_once(db: Session, attempt: int) -> dict[str, int]:
    scrapers = build_scrapers(db)

    if attempt == 1:
        log.info("Fetching IPO list from chittorgarh.com")
        list_upserted = scrapers["list"].scrape_and_store_all()
    else:
        list_upserted = db.scalar(select(func.count()).select_from(Ipo)) or 0
        log.info("Re-run: skipping list fetch (%s IPOs in DB)", list_upserted)

    log.info("Fetching subscription data")
    subscription_updated = scrapers["subscription"].refresh_all()

    log.info("Fetching IPO details")
    details_updated = scrapers["detail"].scrape_all_details()

    log.info("Fetching GMP data (investorgain.com)")
    gmp_updated = scrapers["gmp"].refresh_active_gmp()

    result = {
        "listUpserted": list_upserted,
        "subscriptionUpdated": subscription_updated,
        "detailsUpdated": details_updated,
        "gmpUpdated": gmp_updated,
    }
    print(
        f"Scrape pass {attempt} — "
        f"list={list_upserted}, subscription={subscription_updated}, "
        f"details={details_updated}, gmp={gmp_updated}",
        flush=True,
    )
    return result
