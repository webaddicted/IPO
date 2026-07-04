"""Maps chittorgarh detail-read JSON into ORM-ready structures."""

from __future__ import annotations

import re
from datetime import datetime
from decimal import Decimal
from typing import Any, Optional
from uuid import UUID

from bs4 import BeautifulSoup

from app.db.enums import IpoStatus
from app.scrapers.parse_util import integer, long_val, money, parse_date, percent, strip_html

SITE = "https://www.chittorgarh.com"
_LOGO_BASE = "https://www.chittorgarh.net/images/ipo/"


def _txt(d: dict, key: str) -> Optional[str]:
    v = d.get(key)
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _ipo_kind(data: dict) -> str:
    cat = (_txt(data, "issue_category") or "").lower()
    return "sme" if "sme" in cat else "mainline"


def _derive_status(open_d, close_d, listing_d) -> str:
    from datetime import date

    today = date.today()
    if listing_d and today >= listing_d:
        return IpoStatus.listed.value
    if open_d and close_d and open_d <= today <= close_d:
        return IpoStatus.open.value
    if open_d and today < open_d:
        return IpoStatus.upcoming.value
    if close_d and today > close_d:
        return IpoStatus.closed.value
    return IpoStatus.upcoming.value


def map_ipo_fields(data: dict, chittorgarh_id: int) -> dict[str, Any]:
    slug = _txt(data, "urlrewrite_folder_name") or f"ipo-{chittorgarh_id}"
    lo = money(_txt(data, "issue_price_lower"))
    hi = money(_txt(data, "issue_price_upper"))
    open_d = parse_date(_txt(data, "timetable_issue_open_date") or _txt(data, "issue_open_date"))
    close_d = parse_date(_txt(data, "timetable_issue_close_date") or _txt(data, "issue_close_date"))
    listing_d = parse_date(_txt(data, "timetable_listing_dt"))

    logo = _txt(data, "logo_url")
    if logo and not logo.startswith("http"):
        logo = _LOGO_BASE + logo

    pre = percent(_txt(data, "promoter_shareholding_pre_issue"))
    post = percent(_txt(data, "promoter_shareholding_post_issue"))

    return {
        "source_chittorgarh_id": chittorgarh_id,
        "source_slug": slug,
        "source_url": f"{SITE}/ipo/{slug}/{chittorgarh_id}/",
        "company_name": _txt(data, "company_name") or slug,
        "logo_url": logo,
        "ipo_type": _ipo_kind(data),
        "status": _derive_status(open_d, close_d, listing_d),
        "offer_price_min": lo,
        "offer_price_max": hi,
        "issue_price": money(_txt(data, "issue_price_final")),
        "face_value": money(_txt(data, "face_value")),
        "lot_size": integer(_txt(data, "market_lot_size")),
        "min_investment": money(_txt(data, "ilot_price_minimum")),
        "open_date": open_d,
        "close_date": close_d,
        "allotment_date": parse_date(_txt(data, "timetable_boa_dt")),
        "refund_date": parse_date(_txt(data, "timetable_refunds_dt")),
        "demat_transfer_date": parse_date(_txt(data, "timetable_share_credit_dt")),
        "listing_date": listing_d,
        "listing_at": _txt(data, "ipo_listing_at"),
        "issue_type": _txt(data, "issue_process_type_desc"),
        "sale_type": _txt(data, "offer_type"),
        "total_issue_size_shares": long_val(_txt(data, "issue_size_in_shares")),
        "total_issue_size_amount": money(_txt(data, "issue_size_in_amt")),
        "fresh_issue_shares": long_val(_txt(data, "issue_size_fresh_in_shares")),
        "ofs_shares": long_val(_txt(data, "issue_size_ofs_in_shares")),
        "market_maker_shares": long_val(_txt(data, "shares_offered_market_maker")),
        "anchor_shares_offered": long_val(_txt(data, "shares_offered_anchor_investor")),
        "anchor_investor_url": _txt(data, "anchor_investor_url"),
        "promoter_holding_pre": pre,
        "promoter_holding_post": post,
        "registrar_name": _txt(data, "registrar_name"),
        "nse_symbol": _txt(data, "nse_symbol"),
        "bse_scripcode": _txt(data, "bse_scripcode"),
        "prospectus_drhp": _txt(data, "prospectus_drhp"),
        "prospectus_rhp": _txt(data, "prospectus_rhp"),
        "last_scraped_at": datetime.utcnow(),
    }


def map_company_profile(data: dict, ipo_id: UUID) -> dict[str, Any]:
    return {
        "ipo_id": ipo_id,
        "description": strip_html(_txt(data, "company_desc")),
        "industry": _txt(data, "ipo_industry"),
        "promoters": strip_html(_txt(data, "promoters")),
        "objectives": strip_html(_txt(data, "issue_objects")),
        "website_url": _txt(data, "website"),
        "address_line1": _txt(data, "address_1"),
        "address_line2": _txt(data, "address_2"),
        "address_line3": _txt(data, "address_3"),
        "city": _txt(data, "city"),
        "state": _txt(data, "state"),
        "pin_code": _txt(data, "pin_code"),
        "phone": _txt(data, "phone"),
        "fax": _txt(data, "fax"),
        "email": _txt(data, "email"),
    }


def map_contacts(data: dict, ipo_id: UUID) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    if _txt(data, "registrar_name"):
        rows.append({
            "ipo_id": ipo_id,
            "contact_type": "registrar",
            "name": _txt(data, "registrar_name"),
            "phone": _txt(data, "reg_phone"),
            "fax": _txt(data, "reg_fax"),
            "email": _txt(data, "registrar_email"),
            "website": _txt(data, "reg_website"),
        })
    if _txt(data, "email") or _txt(data, "phone"):
        addr = ", ".join(
            filter(None, [_txt(data, "address_1"), _txt(data, "city"), _txt(data, "state")])
        )
        rows.append({
            "ipo_id": ipo_id,
            "contact_type": "company",
            "name": _txt(data, "company_name"),
            "phone": _txt(data, "phone"),
            "fax": _txt(data, "fax"),
            "email": _txt(data, "email"),
            "website": _txt(data, "website"),
            "address": addr or None,
        })
    return rows


def map_lead_managers(root: dict, data: dict, ipo_id: UUID) -> list[dict[str, Any]]:
    primary_id = None
    primary = root.get("primary_lead_data") or data.get("primary_lead_data")
    if isinstance(primary, dict):
        primary_id = primary.get("id")
    rows = []
    for lm in root.get("ipoLeadManagersList") or []:
        if not isinstance(lm, dict):
            continue
        rows.append({
            "ipo_id": ipo_id,
            "name": _txt(lm, "comp_name") or "—",
            "address": _txt(lm, "address"),
            "website": _txt(lm, "website"),
            "email": _txt(lm, "email"),
            "phone": _txt(lm, "phone"),
            "is_primary": lm.get("id") == primary_id,
        })
    return rows


def map_important_dates(data: dict, ipo_id: UUID) -> list[dict[str, Any]]:
    events = [
        ("IPO Open", _txt(data, "timetable_issue_open_date"), 1),
        ("IPO Close", _txt(data, "timetable_issue_close_date"), 2),
        ("Anchor Bid", _txt(data, "timetable_anchor_bid_dt"), 3),
        ("Allotment", _txt(data, "timetable_boa_dt"), 4),
        ("Refund Initiation", _txt(data, "timetable_refunds_dt"), 5),
        ("Demat Transfer", _txt(data, "timetable_share_credit_dt"), 6),
        ("Anchor Lock-in End (30d)", _txt(data, "timetable_anchor_lockin_end_dt_1"), 7),
        ("Anchor Lock-in End (90d)", _txt(data, "timetable_anchor_lockin_end_dt_2"), 8),
        ("Listing", _txt(data, "timetable_listing_dt"), 9),
    ]
    out = []
    for event, raw, order in events:
        d = parse_date(raw)
        if d:
            out.append({"ipo_id": ipo_id, "event": event, "event_date": d, "sort_order": order})
    return out


def map_lot_tiers(data: dict, ipo_id: UUID) -> list[dict[str, Any]]:
    html = _txt(data, "lotTableHtml")
    if html:
        soup = BeautifulSoup(html, "html.parser")
        rows = []
        for tr in soup.select("table tr"):
            cells = [c.get_text(strip=True) for c in tr.select("td")]
            if len(cells) < 4:
                continue
            applicant = cells[0].strip()
            if not applicant or applicant.lower() == "application":
                continue
            rows.append({
                "ipo_id": ipo_id,
                "applicant": applicant,
                "lots": integer(cells[1]),
                "shares": long_val(cells[2]),
                "amount": money(cells[3]),
            })
        if rows:
            return rows

    tiers = [
        ("Retail (Min)", 1, integer(_txt(data, "market_lot_size")), money(_txt(data, "ilot_price_minimum"))),
        ("Retail (Max)", integer(_txt(data, "ilot_count_maximum")), integer(_txt(data, "ilot_size_shares_maximum")), None),
        ("S-HNI (Min)", integer(_txt(data, "ilot_count_s_hni_min")), integer(_txt(data, "ilot_size_shares_s_hni_min")), money(_txt(data, "ilot_price_s_hni_min"))),
        ("S-HNI (Max)", integer(_txt(data, "ilot_count_s_hni_max")), integer(_txt(data, "ilot_size_shares_s_hni_max")), None),
        ("B-HNI (Min)", integer(_txt(data, "ilot_count_b_hni")), integer(_txt(data, "ilot_size_shares_b_hni")), money(_txt(data, "ilot_price_b_hni"))),
    ]
    out = []
    for applicant, lots, shares, amount in tiers:
        if lots or shares or amount:
            out.append({"ipo_id": ipo_id, "applicant": applicant, "lots": lots, "shares": shares, "amount": amount})
    return out


def map_reservations(data: dict, ipo_id: UUID) -> list[dict[str, Any]]:
    html = _txt(data, "ipo_reservation_desc")
    if html:
        soup = BeautifulSoup(html, "html.parser")
        rows = []
        seen: set[str] = set()
        for tr in soup.select("table tr"):
            cells = [c.get_text(" ", strip=True) for c in tr.select("td")]
            if len(cells) < 2:
                continue
            raw_label = cells[0].strip()
            label = raw_label.lower()
            if "total" in label and "shares offered" in label:
                continue
            category = None
            if "qib" in label and "anchor" not in label and "ex" not in label:
                category = "QIB"
            elif "anchor" in label:
                category = "Anchor Investor"
            elif "qib" in label and "ex" in label:
                category = "QIB (Ex. Anchor)"
            elif "bnii" in label or ("nii" in label and ">" in raw_label):
                category = raw_label
            elif "snii" in label or ("nii" in label and "<" in raw_label):
                category = raw_label
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
            if category in seen:
                n = 2
                while f"{category} ({n})" in seen:
                    n += 1
                category = f"{category} ({n})"
            seen.add(category)
            shares = long_val(cells[1]) if len(cells) > 1 else None
            pct_net = percent(cells[2]) if len(cells) > 2 else None
            pct_total = percent(cells[3]) if len(cells) > 3 else None
            max_allot = integer(cells[4]) if len(cells) > 4 else None
            rows.append({
                "ipo_id": ipo_id,
                "category": category,
                "shares_offered": shares,
                "percent_of_net_issue": pct_net,
                "percent_of_total": pct_total,
                "max_allottees": max_allot,
            })
        if rows:
            return rows

    mapping = [
        ("QIB", "shares_offered_qib"),
        ("Anchor Investor", "shares_offered_anchor_investor"),
        ("NII", "shares_offered_nii"),
        ("Retail", "shares_offered_rii"),
        ("Employee", "shares_offered_emp"),
        ("Market Maker", "shares_offered_market_maker"),
    ]
    out = []
    for cat, field in mapping:
        shares = long_val(_txt(data, field))
        if shares:
            out.append({"ipo_id": ipo_id, "category": cat, "shares_offered": shares})
    return out


def map_anchor_investors(data: dict, ipo_id: UUID) -> list[dict[str, Any]]:
    html = _txt(data, "anchor_investor_detail")
    if not html:
        return []
    soup = BeautifulSoup(html, "html.parser")
    rows = []
    order = 0
    for tr in soup.select("table tr"):
        cells = [c.get_text(" ", strip=True) for c in tr.select("td")]
        if len(cells) < 4:
            continue
        if cells[0].isdigit() or re.match(r"^\d+$", cells[0]):
            order += 1
            entity = cells[1] if len(cells) > 1 else None
            fund = cells[2] if len(cells) > 2 else None
            shares = long_val(cells[3]) if len(cells) > 3 else None
            amt = money(cells[4]) if len(cells) > 4 else None
            pct_alloc = percent(cells[5]) if len(cells) > 5 else None
            pct_issue = percent(cells[6]) if len(cells) > 6 else None
            if entity and entity.lower() not in ("anchor group", "entity"):
                rows.append({
                    "ipo_id": ipo_id,
                    "entity_name": entity,
                    "fund_house": fund,
                    "shares_allotted": shares,
                    "amount_cr": amt,
                    "percent_allocated": pct_alloc,
                    "percent_of_issue": pct_issue,
                    "sort_order": order,
                })
    return rows


def map_review(data: dict, ipo_id: UUID) -> Optional[dict[str, Any]]:
    conclusion = _txt(data, "conclusion")
    if not conclusion and not _txt(data, "review_conclusion"):
        return None
    return {
        "ipo_id": ipo_id,
        "conclusion": conclusion,
        "recommendation": _txt(data, "recommendation"),
        "review_conclusion": _txt(data, "review_conclusion"),
        "cm_rating": money(_txt(data, "cm_rating")),
        "reviewed_at": parse_date(_txt(data, "last_modified_dt")),
    }


def map_drhp_milestones(root: dict, ipo_id: UUID) -> list[dict[str, Any]]:
    out = []
    for row in root.get("drhpDetailsTable") or []:
        if not isinstance(row, dict):
            continue
        code = row.get("drhp_code")
        out.append({
            "ipo_id": ipo_id,
            "milestone_code": int(code) if code is not None else None,
            "description": _txt(row, "drhp_desc"),
            "milestone_date": parse_date(_txt(row, "drhp_code_date") or _txt(row, "drhp_code_date_actual")),
        })
    return out


def map_financials(data: dict, ipo_id: UUID) -> list[dict[str, Any]]:
    html = _txt(data, "financial")
    if not html:
        return []
    soup = BeautifulSoup(html, "html.parser")
    table = soup.select_one("#financialTable, table")
    if not table:
        return []

    headers = table.select("thead th")
    periods: list[str] = []
    for i in range(1, len(headers)):
        p = headers[i].get_text(strip=True)
        if p:
            periods.append("FY" + p.replace("31 Mar ", "").strip())

    by_period: dict[str, dict] = {}
    for tr in table.select("tbody tr"):
        cells = tr.select("td")
        if len(cells) < 2:
            continue
        metric = cells[0].get_text(strip=True).lower()
        for i, period in enumerate(periods):
            if i + 1 >= len(cells):
                break
            val = money(cells[i + 1].get_text())
            if val is None:
                continue
            row = by_period.setdefault(period, {"ipo_id": ipo_id, "period": period})
            if "asset" in metric:
                row["total_assets"] = val
            elif "total income" in metric or "revenue" in metric:
                row["revenue"] = val
            elif "ebitda" in metric and "margin" not in metric:
                row["ebitda"] = val
            elif "profit before tax" in metric or metric == "pbt":
                row["profit_before_tax"] = val
            elif "profit after tax" in metric or metric == "pat":
                row["profit_after_tax"] = val
            elif "net worth" in metric:
                row["net_worth"] = val
            elif "reserves" in metric:
                row["reserves_surplus"] = val
            elif "borrowing" in metric:
                row["total_borrowing"] = val
    return list(by_period.values())


def map_kpis(data: dict, ipo_id: UUID) -> list[dict[str, Any]]:
    specs = [
        ("ROE", "kpi_roe", "%"),
        ("ROCE", "kpi_roce", "%"),
        ("RONW", "kpi_ronw", "%"),
        ("DEBT_EQUITY", "kpi_debt_equity", "x"),
        ("EPS", "kpi_eps", "INR"),
        ("PE_PRE", "pe_ratio", "x"),
        ("NAV", "nav", "INR"),
        ("PAT_MARGIN", "kpi_pat_margin", "%"),
        ("EBITDA_MARGIN", "kpi_ebitda", "%"),
        ("PRICE_TO_BOOK", "price_to_book_value", "x"),
    ]
    out = []
    for metric, field, unit in specs:
        val = percent(_txt(data, field))
        if val is None:
            val = money(_txt(data, field))
        if val is not None:
            out.append({"ipo_id": ipo_id, "metric": metric, "value": val, "unit": unit})
    return out


def map_peers(root: dict, ipo_id: UUID) -> list[dict[str, Any]]:
    out = []
    for p in root.get("ipoPeerComparisonData") or []:
        if isinstance(p, dict) and _txt(p, "company_name"):
            out.append({"ipo_id": ipo_id, "peer_company_name": _txt(p, "company_name")})
    return out
