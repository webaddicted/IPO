"""IPO REST endpoints."""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.db.enums import IpoKind, IpoStatus
from app.db.session import get_db
from app.schemas.ipo import GmpPoint, IpoDetail, IpoSummary, SubscriptionRow
from app.services.ipo_service import IpoService

router = APIRouter(prefix="/api/v1", tags=["ipos"])


@router.get("/ipos/basic", response_model=list[IpoSummary])
def basic(
    type: IpoKind = Query(default=IpoKind.mainline),
    status: IpoStatus | None = Query(default=None),
    db: Session = Depends(get_db),
) -> list[IpoSummary]:
    return IpoService(db).basic(type, status)


@router.get("/ipos/current", response_model=list[IpoSummary])
def current(
    type: IpoKind = Query(default=IpoKind.mainline),
    db: Session = Depends(get_db),
) -> list[IpoSummary]:
    return IpoService(db).current(type)


@router.get("/ipos/listed", response_model=list[IpoSummary])
def listed(
    type: IpoKind = Query(default=IpoKind.mainline),
    db: Session = Depends(get_db),
) -> list[IpoSummary]:
    return IpoService(db).listed(type)


@router.get("/ipos/{ipo_id}", response_model=IpoDetail)
def detail(ipo_id: UUID, db: Session = Depends(get_db)) -> IpoDetail:
    return IpoService(db).detail(ipo_id)


@router.get("/ipos/{ipo_id}/gmp", response_model=list[GmpPoint])
def gmp(ipo_id: UUID, db: Session = Depends(get_db)) -> list[GmpPoint]:
    return IpoService(db).gmp_history(ipo_id)


@router.get("/ipos/{ipo_id}/subscription", response_model=list[SubscriptionRow])
def subscription(ipo_id: UUID, db: Session = Depends(get_db)) -> list[SubscriptionRow]:
    return IpoService(db).subscriptions(ipo_id)
