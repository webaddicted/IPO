"""GMP scraper — investorgain report 331."""

from __future__ import annotations

import logging
from decimal import Decimal, ROUND_HALF_UP

from bs4 import BeautifulSoup
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.enums import IpoKind, IpoStatus
from app.db.models import GmpData, Ipo
from app.scrapers.http_client import ScraperHttpClient
from app.scrapers.parse_util import integer, money, percent

log = logging.getLogger(__name__)

GMP_REPORT = 331


def _text(row: dict, field: str) -> str | None:
    val = row.get(field)
    if val is None:
        return None
    s = str(val).strip()
    return s or None


def _slug_from_row(row: dict) -> str | None:
    folder = _text(row, "~urlrewrite_folder_name")
    if not folder:
        return None
    parts = folder.rstrip("/").split("/")
    for part in reversed(parts):
        if part and not part.isdigit():
            return part
    return None


def _parse_gmp(html: str | None) -> Decimal | None:
    if not html:
        return None
    plain = BeautifulSoup(html, "html.parser").get_text(strip=True)
    return money(plain)


class GmpScraper:
    def __init__(self, db: Session, http: ScraperHttpClient) -> None:
        self._db = db
        self._http = http

    def refresh_active_gmp(self) -> int:
        mainline = self._fetch_gmp_map("ipo")
        sme = self._fetch_gmp_map("sme")

        active = self._db.scalars(
            select(Ipo).where(Ipo.status.in_([IpoStatus.open.value, IpoStatus.upcoming.value]))
        ).all()

        updated = 0
        for ipo in active:
            row = None
            if ipo.ipo_type == IpoKind.sme.value:
                row = sme.get(ipo.source_slug)
            else:
                row = mainline.get(ipo.source_slug)
            if row is None:
                row = mainline.get(ipo.source_slug)
            if row is None:
                row = sme.get(ipo.source_slug)
            if row and self._record(ipo, row):
                updated += 1

        self._db.commit()
        log.info("Refreshed GMP for %s/%s active IPOs", updated, len(active))
        return updated

    def _fetch_gmp_map(self, parameter: str) -> dict[str, dict]:
        result: dict[str, dict] = {}
        try:
            root = self._http.fetch_investorgain_report(GMP_REPORT, parameter, "")
            if root.get("msg") != 1:
                return result
            for row in root.get("reportTableData") or []:
                slug = _slug_from_row(row)
                if slug:
                    result[slug] = row
        except Exception as exc:
            log.warning("GMP report fetch failed for %s: %s", parameter, exc)
        return result

    def _record(self, ipo: Ipo, row: dict) -> bool:
        gmp = _parse_gmp(_text(row, "GMP"))
        if gmp is None:
            return False

        pct = percent(_text(row, "~gmp_percent_calc"))
        issue_price = money(_text(row, "Price (₹)"))
        if issue_price is None:
            issue_price = ipo.issue_price
        if issue_price is None:
            issue_price = ipo.offer_price_max

        est_listing = issue_price + gmp if issue_price is not None else None

        g = GmpData(
            ipo_id=ipo.id,
            gmp_price=gmp,
            issue_price=issue_price,
        )
        if pct is not None:
            g.gmp_percent = pct
        elif issue_price is not None and issue_price > 0:
            g.gmp_percent = (gmp * Decimal("100") / issue_price).quantize(
                Decimal("0.01"), rounding=ROUND_HALF_UP
            )
        g.estimated_listing_price = est_listing
        self._db.add(g)

        ipo.latest_gmp = gmp
        ipo.latest_gmp_percent = g.gmp_percent
        if est_listing is not None:
            ipo.estimated_listing_price = est_listing
        lot = integer(_text(row, "Lot"))
        if lot is not None and ipo.lot_size is None:
            ipo.lot_size = lot
        return True
