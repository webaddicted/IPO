"""Subscription scraper — chittorgarh report 98."""

from __future__ import annotations

import logging

from bs4 import BeautifulSoup
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import Ipo, SubscriptionData
from app.scrapers.http_client import ScraperHttpClient
from app.scrapers.parse_util import money, parse_date

log = logging.getLogger(__name__)

SUBSCRIPTION_REPORT = 98


def _text(row: dict, field: str) -> str | None:
    val = row.get(field)
    if val is None:
        return None
    s = str(val).strip()
    if not s:
        return None
    return BeautifulSoup(s, "html.parser").get_text(strip=True) or None


class SubscriptionScraper:
    def __init__(self, db: Session, http: ScraperHttpClient) -> None:
        self._db = db
        self._http = http

    def refresh_all(self) -> int:
        try:
            root = self._http.fetch_chittorgarh_report(SUBSCRIPTION_REPORT, "all")
            if root.get("msg") != 1:
                return 0

            by_slug: dict[str, dict] = {}
            for row in root.get("reportTableData") or []:
                slug = _text(row, "~URLRewrite_Folder_Name")
                if slug:
                    by_slug[slug] = row

            updated = 0
            for ipo in self._db.scalars(select(Ipo)).all():
                row = by_slug.get(ipo.source_slug)
                if row:
                    self._apply_row(ipo, row)
                    updated += 1

            self._db.commit()
            log.info("Subscription refresh: %s IPOs with live data", updated)
            created = self._ensure_all_snapshots()
            if created:
                self._db.commit()
                log.info("Created %s placeholder subscription snapshots", created)
            return len(self._db.scalars(select(Ipo)).all())
        except Exception as exc:
            log.error("Subscription scrape failed: %s", exc)
            self._db.rollback()
            return 0

    def _apply_row(self, ipo: Ipo, row: dict) -> None:
        total = money(_text(row, "Total (x)"))
        if total is not None:
            ipo.latest_subscription = total

        listed = money(_text(row, "Close Price on Listing (Rs.)"))
        if listed is None:
            listed = money(_text(row, "Open Price on Listing (Rs.)"))
        if listed is not None:
            ipo.listed_price = listed

        sub = self._db.scalar(
            select(SubscriptionData).where(
                SubscriptionData.ipo_id == ipo.id,
                SubscriptionData.bucket == "overall",
            )
        )
        if sub is None:
            sub = SubscriptionData(ipo_id=ipo.id, bucket="overall")
            self._db.add(sub)

        sub.total_subscription = total
        sub.qib_subscription = money(_text(row, "QIB (x)"))
        sub.nii_subscription = money(_text(row, "NII (x)"))
        sub.retail_subscription = money(_text(row, "Retail (x)"))
        sub.employee_subscription = money(_text(row, "Employees (x)"))
        sub.market_maker_subscription = money(_text(row, "Others (x)"))
        sub.subscription_date = parse_date(_text(row, "~issue_open_date_plan"))

    def _ensure_all_snapshots(self) -> int:
        """Create placeholder overall snapshot for IPOs missing from live report."""
        created = 0
        for ipo in self._db.scalars(select(Ipo)).all():
            sub = self._db.scalar(
                select(SubscriptionData).where(
                    SubscriptionData.ipo_id == ipo.id,
                    SubscriptionData.bucket == "overall",
                )
            )
            if sub is None:
                self._db.add(SubscriptionData(ipo_id=ipo.id, bucket="overall"))
                created += 1
        return created
