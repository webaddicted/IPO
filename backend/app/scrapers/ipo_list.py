"""IPO list scraper — chittorgarh report 82."""

from __future__ import annotations

import logging
import re
import time
from datetime import date
from decimal import Decimal

from bs4 import BeautifulSoup
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import Settings
from app.db.enums import IpoKind, IpoStatus
from app.db.models import Ipo
from app.scrapers.http_client import ScraperHttpClient
from app.scrapers.parse_util import chittorgarh_id_from_url, iso_date, money, price_band, strip_html

log = logging.getLogger(__name__)

DATA_API = "https://webnodejs.chittorgarh.com/cloud/report/data-read"
REPORT_ID = 82
SITE = "https://www.chittorgarh.com"
IPO_ID = re.compile(r"/ipo/[^/]+/(\d+)/")


def build_url(parameter: str) -> str:
    today = date.today()
    year = today.year
    month = today.month
    fy_start = year if month >= 4 else year - 1
    fy = f"{fy_start}-{(fy_start + 1) % 100:02d}"
    return f"{DATA_API}/{REPORT_ID}/1/{month}/{year}/{fy}/0/{parameter}?search=&v=1"


def detail_url(company_html: str | None, slug: str) -> str:
    if company_html:
        m = IPO_ID.search(company_html)
        if m:
            return f"{SITE}/ipo/{slug}/{m.group(1)}/"
    return f"{SITE}/ipo/{slug}/"


def _text(row: dict, field: str) -> str | None:
    val = row.get(field)
    if val is None:
        return None
    s = str(val).strip()
    return s or None


def _derive_status(ipo: Ipo) -> IpoStatus:
    today = date.today()
    if ipo.listing_date and today >= ipo.listing_date:
        return IpoStatus.listed
    if (
        ipo.open_date
        and ipo.close_date
        and ipo.open_date <= today <= ipo.close_date
    ):
        return IpoStatus.open
    if ipo.open_date and today < ipo.open_date:
        return IpoStatus.upcoming
    if ipo.close_date and today > ipo.close_date:
        return IpoStatus.closed
    return IpoStatus(ipo.status) if ipo.status else IpoStatus.upcoming


class IpoListScraper:
    def __init__(self, db: Session, http: ScraperHttpClient, settings: Settings) -> None:
        self._db = db
        self._http = http
        self._delay = settings.scraper_polite_delay_ms / 1000.0

    def scrape_and_store_all(self) -> int:
        n = self._scrape_list("mainboard", IpoKind.mainline)
        self._sleep()
        n += self._scrape_list("sme", IpoKind.sme)
        return n

    def _scrape_list(self, parameter: str, kind: IpoKind) -> int:
        count = 0
        try:
            root = self._http.fetch_chittorgarh_report(REPORT_ID, parameter)
            if root.get("msg") != 1:
                log.warning(
                    "data-read returned msg!=1 for %s: %s",
                    parameter,
                    root.get("error"),
                )
                return 0
            rows = root.get("reportTableData") or []
            log.info("Fetched %s %s IPO rows", len(rows), parameter)
            for row in rows:
                try:
                    ipo = self._parse_row(row, kind)
                    if ipo:
                        self._db.merge(ipo)
                        count += 1
                except Exception as exc:
                    log.warning("Skipping unparseable row: %s", exc)
            self._db.commit()
        except Exception as exc:
            log.error("Failed to fetch %s list: %s", parameter, exc)
            self._db.rollback()
        return count

    def _parse_row(self, row: dict, kind: IpoKind) -> Ipo | None:
        slug = _text(row, "~URLRewrite_Folder_Name")
        if not slug:
            return None

        existing = self._db.scalar(select(Ipo).where(Ipo.source_slug == slug))
        company_html = _text(row, "Company")
        cid = chittorgarh_id_from_url(detail_url(company_html, slug))
        if existing is None and cid is None:
            log.warning("Skipping %s — no chittorgarh id", slug)
            return None

        ipo = existing or Ipo(source_slug=slug, source_chittorgarh_id=cid)
        if cid is not None:
            ipo.source_chittorgarh_id = cid
        ipo.ipo_type = kind.value
        ipo.company_name = _text(row, "~IPO") or strip_html(company_html) or slug
        ipo.source_url = detail_url(company_html, slug)
        ipo.logo_url = _text(row, "~compare_image")
        ipo.listing_at = _text(row, "Listing at")

        pricing = _text(row, "Pricing Method")
        if pricing:
            ipo.issue_type = (
                "Bookbuilding IPO" if "book" in pricing.lower() else "Fixed Price IPO"
            )

        ipo.issue_price = money(_text(row, "Issue Price (Rs.)"))
        lo, hi = price_band(_text(row, "Issue Price (Rs.)"))
        if lo is not None:
            ipo.offer_price_min = lo
        if hi is not None:
            ipo.offer_price_max = hi
        if lo is not None and hi is not None and lo == hi:
            ipo.issue_price = lo
        elif ipo.issue_price is None and hi is not None:
            ipo.issue_price = hi

        cr = money(_text(row, "Total Issue Amount (Incl.Firm reservations) (Rs.cr.)"))
        if cr is not None:
            ipo.total_issue_size_amount = cr * Decimal("10000000")

        ipo.open_date = iso_date(_text(row, "~Issue_Open_Date"))
        ipo.close_date = iso_date(_text(row, "~IssueCloseDate"))
        ipo.listing_date = iso_date(_text(row, "~ListingDate"))
        ipo.status = _derive_status(ipo).value
        return ipo

    def _sleep(self) -> None:
        time.sleep(self._delay)
