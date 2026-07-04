"""Tests for detail_mapper parsing."""

from uuid import uuid4

from app.scrapers.detail_mapper import map_ipo_fields, map_reservations


def test_map_ipo_fields_minimal():
    data = {
        "company_name": "Knack Packaging",
        "urlrewrite_folder_name": "knack-packaging-ipo",
        "issue_category": "Mainline IPO",
        "issue_price_lower": "167",
        "issue_price_upper": "176",
        "timetable_issue_open_date": "Monday, July 6, 2026",
        "timetable_issue_close_date": "Tuesday, July 8, 2026",
        "timetable_listing_dt": "Friday, July 11, 2026",
        "market_lot_size": "85",
    }
    fields = map_ipo_fields(data, 2592)
    assert fields["source_chittorgarh_id"] == 2592
    assert fields["company_name"] == "Knack Packaging"
    assert fields["ipo_type"] == "mainline"
    assert fields["open_date"].year == 2026
    assert fields["lot_size"] == 85


def test_map_reservations_from_shares_fields():
    data = {
        "shares_offered_qib": "1000000",
        "shares_offered_nii": "500000",
        "shares_offered_rii": "750000",
    }
    rows = map_reservations(data, uuid4())
    categories = {r["category"] for r in rows}
    assert "QIB" in categories
    assert "NII" in categories
    assert "Retail" in categories
