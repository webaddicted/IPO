"""POC scraper — populate one IPO and all child tables from detail-read API."""

from __future__ import annotations

import logging
from typing import Any
from uuid import UUID

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.config import get_settings
from app.db.models import (
    AnchorInvestor,
    CompanyProfile,
    DrhpMilestone,
    FinancialPeriod,
    ImportantDate,
    Ipo,
    IpoContact,
    IpoReservation,
    IpoReview,
    KpiMetric,
    LeadManager,
    LotSizeTier,
    PeerComparison,
)
from app.scrapers.detail_mapper import (
    map_anchor_investors,
    map_company_profile,
    map_contacts,
    map_drhp_milestones,
    map_financials,
    map_important_dates,
    map_ipo_fields,
    map_kpis,
    map_lead_managers,
    map_lot_tiers,
    map_peers,
    map_reservations,
    map_review,
)
from app.scrapers.http_client import ScraperHttpClient

log = logging.getLogger(__name__)

_CHILD_TABLES = (
    (IpoContact, "contacts"),
    (LeadManager, "leadManagers"),
    (ImportantDate, "importantDates"),
    (LotSizeTier, "lotSizes"),
    (IpoReservation, "reservations"),
    (AnchorInvestor, "anchorInvestors"),
    (DrhpMilestone, "drhpMilestones"),
    (FinancialPeriod, "financials"),
    (KpiMetric, "kpis"),
    (PeerComparison, "peers"),
)


def scrape_poc_ipo(db: Session, chittorgarh_id: int) -> dict[str, Any]:
    """Fetch detail-read JSON and upsert master + all child tables."""
    settings = get_settings()
    http = ScraperHttpClient(settings)

    root = http.fetch_ipo_detail(chittorgarh_id)
    if root.get("msg") != 1:
        raise ValueError(f"detail-read failed for id={chittorgarh_id}: {root.get('error')}")

    data_list = root.get("ipoData") or []
    if not data_list:
        raise ValueError(f"No ipoData for chittorgarh id={chittorgarh_id}")

    data = data_list[0]
    ipo_fields = map_ipo_fields(data, chittorgarh_id)

    ipo = db.scalar(
        select(Ipo).where(Ipo.source_chittorgarh_id == chittorgarh_id)
    )
    if ipo is None:
        ipo = Ipo(**ipo_fields)
        db.add(ipo)
        db.flush()
    else:
        for key, val in ipo_fields.items():
            setattr(ipo, key, val)

    ipo_id: UUID = ipo.id
    counts: dict[str, int] = {"ipo": 1}

    profile = db.scalar(select(CompanyProfile).where(CompanyProfile.ipo_id == ipo_id))
    profile_data = map_company_profile(data, ipo_id)
    if profile is None:
        db.add(CompanyProfile(**profile_data))
        counts["companyProfile"] = 1
    else:
        for key, val in profile_data.items():
            if key != "ipo_id":
                setattr(profile, key, val)
        counts["companyProfile"] = 1

    review_data = map_review(data, ipo_id)
    if review_data:
        review = db.scalar(select(IpoReview).where(IpoReview.ipo_id == ipo_id))
        if review is None:
            db.add(IpoReview(**review_data))
        else:
            for key, val in review_data.items():
                if key != "ipo_id":
                    setattr(review, key, val)
        counts["review"] = 1
    else:
        counts["review"] = 0

    _replace_rows(db, IpoContact, ipo_id, map_contacts(data, ipo_id), counts, "contacts")
    _replace_rows(db, LeadManager, ipo_id, map_lead_managers(root, data, ipo_id), counts, "leadManagers")
    _replace_rows(db, ImportantDate, ipo_id, map_important_dates(data, ipo_id), counts, "importantDates")
    _replace_rows(db, LotSizeTier, ipo_id, map_lot_tiers(data, ipo_id), counts, "lotSizes")
    _replace_rows(db, IpoReservation, ipo_id, map_reservations(data, ipo_id), counts, "reservations")
    _replace_rows(db, AnchorInvestor, ipo_id, map_anchor_investors(data, ipo_id), counts, "anchorInvestors")
    _replace_rows(db, DrhpMilestone, ipo_id, map_drhp_milestones(root, ipo_id), counts, "drhpMilestones")
    _replace_rows(db, FinancialPeriod, ipo_id, map_financials(data, ipo_id), counts, "financials")
    _replace_rows(db, KpiMetric, ipo_id, map_kpis(data, ipo_id), counts, "kpis")
    _replace_rows(db, PeerComparison, ipo_id, map_peers(root, ipo_id), counts, "peers")

    db.commit()
    log.info("POC scrape complete for %s (%s)", ipo.company_name, chittorgarh_id)

    return {
        "status": "ok",
        "chittorgarhId": chittorgarh_id,
        "ipoId": str(ipo_id),
        "companyName": ipo.company_name,
        "tablesPopulated": counts,
    }


def _replace_rows(
    db: Session,
    model: type,
    ipo_id: UUID,
    rows: list[dict],
    counts: dict[str, int],
    key: str,
) -> None:
    db.execute(delete(model).where(model.ipo_id == ipo_id))
    for row in rows:
        db.add(model(**row))
    counts[key] = len(rows)
