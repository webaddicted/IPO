"""Tests for parse_util helpers."""

from datetime import date
from decimal import Decimal

from app.scrapers.ipo_list import build_url, detail_url
from app.scrapers.parse_util import iso_date, money, price_band, strip_html


def test_money_parses_rupee():
    assert money("₹1,234.50/-") == Decimal("1234.50")


def test_price_band_range():
    lo, hi = price_band("₹157 to ₹166")
    assert lo == Decimal("157")
    assert hi == Decimal("166")


def test_build_url_targets_report_82():
    url = build_url("mainboard")
    assert "/cloud/report/data-read/82/1/" in url
    assert url.endswith("/mainboard?search=&v=1")


def test_detail_url_extracts_numeric_id():
    html = (
        '<a href="https://www.chittorgarh.com/ipo/aastha-spintex-ipo/2678/" '
        'title="Aastha Spintex IPO Details">Aastha Spintex Ltd.</a>'
    )
    assert (
        detail_url(html, "aastha-spintex-ipo")
        == "https://www.chittorgarh.com/ipo/aastha-spintex-ipo/2678/"
    )


def test_detail_url_fallback_without_id():
    assert detail_url("no anchor", "foo-ipo") == "https://www.chittorgarh.com/ipo/foo-ipo/"


def test_strip_html():
    assert strip_html("<a href='x'>Aastha Spintex Ltd.</a> ") == "Aastha Spintex Ltd."


def test_iso_date_converts_instant_to_ist_date():
    assert iso_date("2026-09-24T18:28:39.000Z") == date(2026, 9, 24)
    assert iso_date("2026-06-23T00:00:00.000Z") == date(2026, 6, 23)
    assert iso_date("") is None
    assert iso_date(None) is None
