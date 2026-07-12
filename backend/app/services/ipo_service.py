"""Read-side IPO service assembling API DTOs."""

from __future__ import annotations

from uuid import UUID

from fastapi import HTTPException
from sqlalchemy import case, select
from sqlalchemy.orm import Session

from app.db.enums import IpoKind, IpoStatus
from app.db.models import (
    AnchorInvestor,
    CompanyProfile,
    DrhpMilestone,
    FinancialPeriod,
    GmpHistory,
    ImportantDate,
    Ipo,
    IpoContact,
    IpoReservation,
    IpoReview,
    KpiMetric,
    LeadManager,
    LotSizeTier,
    PeerComparison,
    SubscriptionSnapshot,
)
from app.schemas.ipo import (
    AnchorInvestorRow,
    CompanyProfileSchema,
    ContactRow,
    DrhpMilestoneRow,
    FinancialRow,
    GmpPoint,
    ImportantDateRow,
    IpoDetail,
    IpoEntity,
    IpoSummary,
    KpiRow,
    LeadManagerRow,
    LotSizeRow,
    PeerRow,
    ReservationRow,
    ReviewRow,
    SubscriptionRow,
)


class IpoService:
    # Current IPO tab order: open → closed → upcoming
    _CURRENT_STATUS_ORDER = case(
        (Ipo.status == IpoStatus.open.value, 1),
        (Ipo.status == IpoStatus.closed.value, 2),
        (Ipo.status == IpoStatus.upcoming.value, 3),
        else_=4,
    )

    def __init__(self, db: Session) -> None:
        self._db = db

    def current(self, kind: IpoKind) -> list[IpoSummary]:
        statuses = [IpoStatus.upcoming.value, IpoStatus.open.value, IpoStatus.closed.value]
        rows = self._db.scalars(
            select(Ipo)
            .where(Ipo.ipo_type == kind.value, Ipo.status.in_(statuses))
            .order_by(self._CURRENT_STATUS_ORDER, Ipo.open_date.desc().nulls_last())
        ).all()
        return [IpoSummary.model_validate(r) for r in rows]

    def listed(self, kind: IpoKind) -> list[IpoSummary]:
        rows = self._db.scalars(
            select(Ipo)
            .where(Ipo.ipo_type == kind.value, Ipo.status == IpoStatus.listed.value)
            .order_by(Ipo.listing_date.desc())
        ).all()
        return [IpoSummary.model_validate(r) for r in rows]

    def basic(self, kind: IpoKind, status: IpoStatus | None) -> list[IpoSummary]:
        q = select(Ipo).where(Ipo.ipo_type == kind.value)
        if status is None:
            q = q.order_by(Ipo.open_date.desc())
        elif status == IpoStatus.listed:
            q = q.where(Ipo.status == status.value).order_by(Ipo.listing_date.desc())
        else:
            q = q.where(Ipo.status == status.value).order_by(Ipo.open_date.desc())
        rows = self._db.scalars(q).all()
        return [IpoSummary.model_validate(r) for r in rows]

    def detail(self, ipo_id: UUID) -> IpoDetail:
        ipo = self._db.get(Ipo, ipo_id)
        if not ipo:
            raise HTTPException(status_code=404, detail=f"IPO not found: {ipo_id}")

        gmp = self._db.scalars(
            select(GmpHistory)
            .where(GmpHistory.ipo_id == ipo_id)
            .order_by(GmpHistory.recorded_at.asc())
        ).all()
        subs = self._db.scalars(
            select(SubscriptionSnapshot).where(SubscriptionSnapshot.ipo_id == ipo_id)
        ).all()
        fins = self._db.scalars(
            select(FinancialPeriod)
            .where(FinancialPeriod.ipo_id == ipo_id)
            .order_by(FinancialPeriod.period.desc())
        ).all()
        kpis = self._db.scalars(select(KpiMetric).where(KpiMetric.ipo_id == ipo_id)).all()
        resv = self._db.scalars(
            select(IpoReservation).where(IpoReservation.ipo_id == ipo_id)
        ).all()
        lots = self._db.scalars(select(LotSizeTier).where(LotSizeTier.ipo_id == ipo_id)).all()
        dates = self._db.scalars(
            select(ImportantDate)
            .where(ImportantDate.ipo_id == ipo_id)
            .order_by(ImportantDate.sort_order.asc())
        ).all()
        company = self._db.scalar(
            select(CompanyProfile).where(CompanyProfile.ipo_id == ipo_id)
        )
        contacts = self._db.scalars(
            select(IpoContact).where(IpoContact.ipo_id == ipo_id)
        ).all()
        lead_managers = self._db.scalars(
            select(LeadManager).where(LeadManager.ipo_id == ipo_id)
        ).all()
        anchors = self._db.scalars(
            select(AnchorInvestor)
            .where(AnchorInvestor.ipo_id == ipo_id)
            .order_by(AnchorInvestor.sort_order.asc())
        ).all()
        review = self._db.scalar(select(IpoReview).where(IpoReview.ipo_id == ipo_id))
        drhp = self._db.scalars(
            select(DrhpMilestone).where(DrhpMilestone.ipo_id == ipo_id)
        ).all()
        peers = self._db.scalars(
            select(PeerComparison).where(PeerComparison.ipo_id == ipo_id)
        ).all()

        entity = IpoEntity.model_validate(ipo)
        if entity.registrar is None:
            entity.registrar = ipo.registrar_name

        return IpoDetail(
            ipo=entity,
            gmp=[GmpPoint.model_validate(g) for g in gmp],
            subscriptions=[SubscriptionRow.model_validate(s) for s in subs],
            financials=[FinancialRow.model_validate(f) for f in fins],
            kpis=[KpiRow.model_validate(k) for k in kpis],
            reservations=[ReservationRow.model_validate(r) for r in resv],
            lot_sizes=[LotSizeRow.model_validate(l) for l in lots],
            important_dates=[ImportantDateRow.model_validate(d) for d in dates],
            company=CompanyProfileSchema.model_validate(company) if company else None,
            contacts=[ContactRow.model_validate(c) for c in contacts],
            lead_managers=[LeadManagerRow.model_validate(lm) for lm in lead_managers],
            anchor_investors=[AnchorInvestorRow.model_validate(a) for a in anchors],
            review=ReviewRow.model_validate(review) if review else None,
            drhp_milestones=[DrhpMilestoneRow.model_validate(m) for m in drhp],
            peers=[PeerRow.model_validate(p) for p in peers],
        )

    def gmp_history(self, ipo_id: UUID) -> list[GmpPoint]:
        if not self._db.get(Ipo, ipo_id):
            raise HTTPException(status_code=404, detail=f"IPO not found: {ipo_id}")
        rows = self._db.scalars(
            select(GmpHistory)
            .where(GmpHistory.ipo_id == ipo_id)
            .order_by(GmpHistory.recorded_at.asc())
        ).all()
        return [GmpPoint.model_validate(g) for g in rows]

    def subscriptions(self, ipo_id: UUID) -> list[SubscriptionRow]:
        if not self._db.get(Ipo, ipo_id):
            raise HTTPException(status_code=404, detail=f"IPO not found: {ipo_id}")
        rows = self._db.scalars(
            select(SubscriptionSnapshot).where(SubscriptionSnapshot.ipo_id == ipo_id)
        ).all()
        return [SubscriptionRow.model_validate(s) for s in rows]
