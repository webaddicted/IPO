"""IPO detail scraper — chittorgarh detail-read API."""

from __future__ import annotations

import logging
import re
import time
from datetime import date, datetime, timezone
from decimal import Decimal
from uuid import UUID

from bs4 import BeautifulSoup
from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.config import Settings
from app.db.enums import IpoStatus
from app.db.models import (
    CompanyInfo,
    FinancialData,
    ImportantDate,
    Ipo,
    IpoReservation,
    KpiData,
    LotSizeTier,
)
from app.scrapers.http_client import ScraperHttpClient
from app.scrapers.parse_util import (
    chittorgarh_id_from_url,
    integer,
    long_val,
    money,
    parse_date,
    percent,
    price_band,
    strip_html,
)

log = logging.getLogger(__name__)

_PERCENT_RE = re.compile(r"([0-9]+(?:\.[0-9]+)?)\s*%")


def _text(node: dict, field: str) -> str | None:
    val = node.get(field)
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


def _extract_percent(s: str | None) -> str | None:
    if not s:
        return None
    m = _PERCENT_RE.search(s)
    return f"{m.group(1)}%" if m else None


class IpoDetailScraper:
    def __init__(self, db: Session, http: ScraperHttpClient, settings: Settings) -> None:
        self._db = db
        self._http = http
        self._delay = 0.8

    def scrape_detail(self, slug: str) -> bool:
        ipo = self._db.scalar(select(Ipo).where(Ipo.source_slug == slug))
        if not ipo:
            return False

        cid = chittorgarh_id_from_url(ipo.source_url)
        if cid is None:
            log.warning("No chittorgarh id in source_url for %s", slug)
            return False

        try:
            root = self._http.fetch_ipo_detail(cid)
            if root.get("msg") != 1:
                return False
            data_list = root.get("ipoData") or []
            if not data_list:
                return False
            data = data_list[0]

            self._apply_ipo_fields(ipo, data)
            self._upsert_company(ipo.id, data, root.get("ipoLeadManagersList") or [])
            self._replace_financials(ipo.id, _text(data, "financial"))
            self._replace_kpis(ipo.id, data)
            self._replace_reservations(ipo.id, data)
            self._replace_lot_sizes(ipo.id, data)
            self._replace_important_dates(ipo.id, data, ipo)
            ipo.last_scraped_at = datetime.now(timezone.utc)
            self._db.commit()
            log.info("Detail scraped for %s", slug)
            return True
        except Exception as exc:
            log.error("Detail scrape failed for %s: %s", slug, exc)
            self._db.rollback()
            return False

    def scrape_all_details(self) -> int:
        all_ipos = self._db.scalars(select(Ipo)).all()
        n = 0
        for ipo in all_ipos:
            if self.scrape_detail(ipo.source_slug):
                n += 1
            time.sleep(self._delay)
        return n

    def _apply_ipo_fields(self, ipo: Ipo, d: dict) -> None:
        lo, hi = price_band(_text(d, "issue_price_band"))
        if lo is not None:
            ipo.offer_price_min = lo
        if hi is not None:
            ipo.offer_price_max = hi

        final_price = money(_text(d, "issue_price_final"))
        if final_price is None:
            final_price = money(_text(d, "iissue_price_retail_cutoff"))
        if final_price is not None:
            ipo.issue_price = final_price

        ipo.face_value = money(_text(d, "face_value"))
        ipo.lot_size = integer(_text(d, "market_lot_size"))
        ipo.min_investment = money(_text(d, "ilot_price_minimum"))
        ipo.sale_type = _text(d, "offer_type")
        ipo.issue_type = _text(d, "issue_process_type_desc")
        ipo.listing_at = _text(d, "ipo_listing_at")
        ipo.registrar_name = _text(d, "registrar_name")
        ipo.total_issue_size_shares = long_val(_text(d, "issue_size_in_shares"))
        amt = money(_text(d, "issue_size_in_amt"))
        if amt is not None:
            ipo.total_issue_size_amount = amt
        ipo.fresh_issue_shares = long_val(_text(d, "issue_size_fresh_in_shares"))
        ipo.ofs_shares = long_val(_text(d, "issue_size_ofs_in_shares"))
        ipo.market_maker_shares = long_val(_text(d, "shares_offered_market_maker"))
        ipo.open_date = parse_date(_text(d, "timetable_issue_open_date"))
        ipo.close_date = parse_date(_text(d, "timetable_issue_close_date"))
        ipo.allotment_date = parse_date(_text(d, "timetable_boa_dt"))
        ipo.refund_date = parse_date(_text(d, "timetable_refunds_dt"))
        ipo.demat_transfer_date = parse_date(_text(d, "timetable_share_credit_dt"))
        ipo.listing_date = parse_date(_text(d, "timetable_listing_dt"))

        if not ipo.logo_url:
            logo = _text(d, "logo_url")
            if logo and not logo.startswith("http"):
                ipo.logo_url = f"https://www.chittorgarh.net/images/ipo/{logo}"

        ipo.status = _derive_status(ipo).value

    def _upsert_company(self, ipo_id: UUID, d: dict, lead_managers: list) -> None:
        c = self._db.scalar(select(CompanyInfo).where(CompanyInfo.ipo_id == ipo_id))
        if c is None:
            c = CompanyInfo(ipo_id=ipo_id)
            self._db.add(c)

        c.description = strip_html(_text(d, "company_desc"))
        c.promoters = strip_html(_text(d, "promoters"))
        c.objectives = strip_html(_text(d, "issue_objects"))
        c.website_url = _text(d, "website")
        c.industry = _text(d, "ipo_industry")
        c.address_line1 = _text(d, "address_1")
        c.city = _text(d, "city")
        c.state = _text(d, "state")
        c.phone = _text(d, "phone")
        c.email = _text(d, "email")

    def _replace_financials(self, ipo_id: UUID, financial_html: str | None) -> None:
        if not financial_html:
            return
        self._db.execute(delete(FinancialData).where(FinancialData.ipo_id == ipo_id))

        soup = BeautifulSoup(financial_html, "html.parser")
        table = soup.select_one("#financialTable, table")
        if not table:
            return

        headers = table.select("thead th")
        periods: list[str] = []
        for i in range(1, len(headers)):
            p = headers[i].get_text(strip=True)
            if p:
                periods.append("FY" + p.replace("31 Mar ", "").strip())

        by_period: dict[str, FinancialData] = {}
        for row in table.select("tbody tr"):
            cells = row.select("td")
            if len(cells) < 2:
                continue
            metric = cells[0].get_text(strip=True).lower()
            for i, period in enumerate(periods):
                if i + 1 >= len(cells):
                    break
                val = money(cells[i + 1].get_text())
                if val is None:
                    continue
                fin = by_period.get(period)
                if fin is None:
                    fin = FinancialData(ipo_id=ipo_id, period=period)
                    by_period[period] = fin
                    self._db.add(fin)
                self._apply_financial_metric(fin, metric, val)

    def _apply_financial_metric(self, fin: FinancialData, metric: str, val: Decimal) -> None:
        if "asset" in metric:
            fin.total_assets = val
        elif "total income" in metric or "revenue" in metric:
            fin.revenue = val
        elif "profit after tax" in metric or metric == "pat":
            fin.profit_after_tax = val
        elif "profit before tax" in metric or metric == "pbt":
            fin.profit_before_tax = val
        elif "ebitda" in metric and "margin" not in metric:
            fin.ebitda = val
        elif "net worth" in metric:
            fin.net_worth = val
        elif "reserves" in metric:
            fin.reserves_surplus = val
        elif "borrowing" in metric:
            fin.total_borrowing = val

    def _replace_kpis(self, ipo_id: UUID, d: dict) -> None:
        metrics = {
            "ROE": "kpi_roe",
            "ROCE": "kpi_roce",
            "RONW": "kpi_ronw",
            "DEBT_EQUITY": "kpi_debt_equity",
            "EPS": "kpi_eps",
            "PE_PRE": "pe_ratio",
            "NAV": "nav",
            "PAT_MARGIN": "kpi_pat_margin",
            "EBITDA_MARGIN": "kpi_ebitda",
        }
        existing = {
            k.metric: k
            for k in self._db.scalars(select(KpiData).where(KpiData.ipo_id == ipo_id)).all()
        }
        for key, field in metrics.items():
            val = percent(_text(d, field))
            if val is None:
                val = money(_text(d, field))
            if val is None:
                continue
            k = existing.get(key)
            if k is None:
                k = KpiData(ipo_id=ipo_id, metric=key)
                self._db.add(k)
            k.value = val
            if key in ("PAT_MARGIN", "EBITDA_MARGIN", "ROE", "ROCE", "RONW"):
                k.unit = "%"
            elif key in ("EPS", "NAV"):
                k.unit = "INR"
            else:
                k.unit = "x"

    def _replace_reservations(self, ipo_id: UUID, d: dict) -> None:
        self._db.execute(delete(IpoReservation).where(IpoReservation.ipo_id == ipo_id))

        qib = long_val(_text(d, "shares_offered_qib")) or 0
        nii = long_val(_text(d, "shares_offered_nii")) or 0
        retail = long_val(_text(d, "shares_offered_rii")) or 0
        emp = long_val(_text(d, "shares_offered_emp")) or 0
        mm = long_val(_text(d, "shares_offered_market_maker")) or 0

        if qib + nii + retail + emp + mm > 0:
            self._save_reservation(
                ipo_id, "QIB", qib or None,
                percent(_extract_percent(_text(d, "shares_offered_qib_percentage_temp"))),
            )
            self._save_reservation(
                ipo_id, "NII", nii or None,
                percent(_extract_percent(_text(d, "shares_offered_nii_percentage_temp"))),
            )
            self._save_reservation(
                ipo_id, "Retail", retail or None,
                percent(_extract_percent(_text(d, "shares_offered_rii_percentage_temp"))),
            )
            self._save_reservation(ipo_id, "Employee", emp or None, None)
            self._save_reservation(ipo_id, "Market Maker", mm or None, None)
        else:
            html = _text(d, "ipo_reservation_desc")
            if html:
                self._parse_reservation_table(ipo_id, html)

    def _parse_reservation_table(self, ipo_id: UUID, html: str) -> None:
        soup = BeautifulSoup(html, "html.parser")
        for row in soup.select("table tr"):
            cells = row.select("td")
            if len(cells) < 2:
                continue
            label = cells[0].get_text(strip=True).lower()
            if "anchor" in label or "bnii" in label or "snii" in label:
                continue
            category = None
            if "qib" in label:
                category = "QIB"
            elif "nii" in label or "hni" in label:
                category = "NII"
            elif "retail" in label:
                category = "Retail"
            elif "employee" in label or "emp" in label:
                category = "Employee"
            elif "market maker" in label:
                category = "Market Maker"
            if not category:
                continue
            shares = long_val(cells[1].get_text())
            pct = percent(cells[2].get_text()) if len(cells) > 2 else None
            if pct is None and len(cells) > 3:
                pct = percent(cells[3].get_text())
            if shares or pct:
                self._save_reservation(ipo_id, category, shares, pct)

    def _save_reservation(
        self,
        ipo_id: UUID,
        category: str,
        shares: int | None,
        pct: Decimal | None,
    ) -> None:
        if shares is None and pct is None:
            return
        r = IpoReservation(
            ipo_id=ipo_id,
            category=category,
            shares_offered=shares,
            percent_of_total=pct,
        )
        self._db.add(r)

    def _replace_lot_sizes(self, ipo_id: UUID, d: dict) -> None:
        self._db.execute(delete(LotSizeTier).where(LotSizeTier.ipo_id == ipo_id))
        self._save_lot(
            ipo_id, "Retail (Min)", 1,
            integer(_text(d, "market_lot_size")),
            money(_text(d, "ilot_price_minimum")),
        )
        self._save_lot(
            ipo_id, "S-HNI (Min)",
            integer(_text(d, "ilot_count_s_hni_min")),
            integer(_text(d, "ilot_size_shares_s_hni_min")),
            money(_text(d, "ilot_price_s_hni_min")),
        )
        self._save_lot(
            ipo_id, "B-HNI (Min)",
            integer(_text(d, "ilot_count_b_hni")),
            integer(_text(d, "ilot_size_shares_b_hni")),
            money(_text(d, "ilot_price_b_hni")),
        )

    def _save_lot(
        self,
        ipo_id: UUID,
        applicant: str,
        lots: int | None,
        shares: int | None,
        amount: Decimal | None,
    ) -> None:
        if lots is None and shares is None and amount is None:
            return
        t = LotSizeTier(
            ipo_id=ipo_id,
            applicant=applicant,
            lots=lots,
            shares=shares,
            amount=amount,
        )
        self._db.add(t)

    def _replace_important_dates(self, ipo_id: UUID, d: dict, ipo: Ipo) -> None:
        self._db.execute(delete(ImportantDate).where(ImportantDate.ipo_id == ipo_id))
        added = 0
        added += self._add_date(ipo_id, "IPO Open", parse_date(_text(d, "timetable_issue_open_date")), 1)
        added += self._add_date(ipo_id, "IPO Close", parse_date(_text(d, "timetable_issue_close_date")), 2)
        added += self._add_date(ipo_id, "Allotment", parse_date(_text(d, "timetable_boa_dt")), 3)
        added += self._add_date(ipo_id, "Refund Initiation", parse_date(_text(d, "timetable_refunds_dt")), 4)
        added += self._add_date(ipo_id, "Demat Transfer", parse_date(_text(d, "timetable_share_credit_dt")), 5)
        added += self._add_date(ipo_id, "Listing", parse_date(_text(d, "timetable_listing_dt")), 6)

        if added == 0:
            self._add_date(ipo_id, "IPO Open", ipo.open_date, 1)
            self._add_date(ipo_id, "IPO Close", ipo.close_date, 2)
            self._add_date(ipo_id, "Allotment", ipo.allotment_date, 3)
            self._add_date(ipo_id, "Refund Initiation", ipo.refund_date, 4)
            self._add_date(ipo_id, "Demat Transfer", ipo.demat_transfer_date, 5)
            self._add_date(ipo_id, "Listing", ipo.listing_date, 6)

    def _add_date(self, ipo_id: UUID, event: str, event_date: date | None, order: int) -> int:
        if event_date is None:
            return 0
        self._db.add(
            ImportantDate(
                ipo_id=ipo_id,
                event=event,
                event_date=event_date,
                sort_order=order,
            )
        )
        return 1
