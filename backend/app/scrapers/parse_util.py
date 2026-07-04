"""Defensive text-to-value helpers for scraped data."""

from __future__ import annotations

import re
from datetime import date, datetime
from decimal import Decimal, InvalidOperation
from zoneinfo import ZoneInfo

from bs4 import BeautifulSoup

_NUMBER = re.compile(r"-?[0-9][0-9,]*\.?[0-9]*")
_DATE_SUB = re.compile(r"[A-Za-z]{3,}\.?\s+\d{1,2},?\s+\d{4}")
_CHITTORGARH_ID = re.compile(r"/ipo/[^/]+/(\d+)/?")

_DATE_FORMATS = (
    "%A, %B %d, %Y",
    "%B %d, %Y",
    "%d %b %Y",
    "%a, %b %d, %Y",
    "%d-%m-%Y",
    "%Y-%m-%d",
    "%B %d, %Y",
)


def money(s: str | None) -> Decimal | None:
    if not s:
        return None
    m = _NUMBER.search(s.replace(",", ""))
    if not m:
        return None
    try:
        return Decimal(m.group())
    except InvalidOperation:
        return None


def integer(s: str | None) -> int | None:
    b = money(s)
    return int(b) if b is not None else None


def long_val(s: str | None) -> int | None:
    b = money(s)
    return int(b) if b is not None else None


def price_band(s: str | None) -> tuple[Decimal | None, Decimal | None]:
    if not s:
        return None, None
    cleaned = s.replace(",", "")
    matches = _NUMBER.findall(cleaned)
    lo = Decimal(matches[0]) if matches else None
    hi = Decimal(matches[1]) if len(matches) > 1 else lo
    return lo, hi


def parse_date(s: str | None) -> date | None:
    if not s or not s.strip():
        return None
    t = s.strip()
    if t in {".", "[.]", "—", "-", "N/A", "NA", "TBA"}:
        return None
    for fmt in _DATE_FORMATS:
        try:
            return datetime.strptime(t, fmt).date()
        except ValueError:
            continue
    m = _DATE_SUB.search(t)
    if m:
        sub = m.group().replace(".", "")
        for fmt in _DATE_FORMATS:
            try:
                return datetime.strptime(sub, fmt).date()
            except ValueError:
                continue
    return None


def percent(s: str | None) -> Decimal | None:
    if not s or not s.strip():
        return None
    return money(s.replace("%", ""))


def chittorgarh_id_from_url(url: str | None) -> int | None:
    if not url:
        return None
    m = _CHITTORGARH_ID.search(url)
    return int(m.group(1)) if m else None


def strip_html(html: str | None) -> str | None:
    if not html or not html.strip():
        return None
    text = BeautifulSoup(html, "html.parser").get_text(strip=True)
    return text or None


def slug_from_url(url: str | None) -> str | None:
    if not url or not url.strip():
        return None
    parts = url.rstrip("/").split("/")
    return parts[-1] if parts else None


def iso_date(s: str | None) -> date | None:
    if not s or not s.strip():
        return None
    try:
        dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
        return dt.astimezone(ZoneInfo("Asia/Kolkata")).date()
    except ValueError:
        return parse_date(s)
