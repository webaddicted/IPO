"""API response shape contract tests."""

from datetime import date
from decimal import Decimal
from uuid import uuid4

from app.schemas.allotment import AllotmentOutcome, AllotmentResult
from app.schemas.ipo import IpoDetail, IpoEntity, IpoSummary


def test_ipo_summary_serializes_camel_case():
    data = IpoSummary(
        id=uuid4(),
        source_slug="uhm-vacation-ipo",
        company_name="UHM Vacation",
        ipo_type="sme",
        status="closed",
        offer_price_min=Decimal("157"),
        offer_price_max=Decimal("166"),
        latest_subscription=Decimal("2.36"),
    ).model_dump(by_alias=True)
    assert "companyName" in data
    assert "sourceSlug" in data
    assert "offerPriceMin" in data
    assert data["companyName"] == "UHM Vacation"


def test_ipo_detail_aggregate_keys():
    ipo_id = uuid4()
    detail = IpoDetail(
        ipo=IpoEntity(
            id=ipo_id,
            source_slug="test",
            company_name="Test Co",
            ipo_type="mainline",
            status="open",
        ),
        gmp=[],
        subscriptions=[],
        financials=[],
        kpis=[],
        reservations=[],
        lot_sizes=[],
        important_dates=[],
        company=None,
        contacts=[],
        lead_managers=[],
        anchor_investors=[],
        review=None,
        drhp_milestones=[],
        peers=[],
    )
    dumped = detail.model_dump(by_alias=True)
    assert set(dumped.keys()) == {
        "ipo",
        "gmp",
        "subscriptions",
        "financials",
        "kpis",
        "reservations",
        "lotSizes",
        "importantDates",
        "company",
        "contacts",
        "leadManagers",
        "anchorInvestors",
        "review",
        "drhpMilestones",
        "peers",
    }


def test_allotment_result_manual_check():
    r = AllotmentResult.manual("UHM", "Bigshare", "https://example.com")
    dumped = r.model_dump(by_alias=True)
    assert dumped["outcome"] == AllotmentOutcome.manual_check_required.value
    assert dumped["manualCheckUrl"] == "https://example.com"
