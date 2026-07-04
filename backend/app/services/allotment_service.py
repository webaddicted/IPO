"""Allotment status resolution."""

from __future__ import annotations

from enum import Enum
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import Ipo
from app.schemas.allotment import AllotmentOutcome, AllotmentRequest, AllotmentResult


class RegistrarPortal(str, Enum):
    BIGSHARE = "Bigshare Services"
    LINKINTIME = "Link Intime India"
    KFINTECH = "KFin Technologies"
    MAASHITLA = "Maashitla Securities"
    CAMEO = "Cameo Corporate Services"
    UNKNOWN = "Registrar"

    @property
    def status_url(self) -> str | None:
        return {
            RegistrarPortal.BIGSHARE: "https://ipo.bigshareonline.com/ipo_Allotment.html",
            RegistrarPortal.LINKINTIME: "https://linkintime.co.in/initial_offer/public-issues.html",
            RegistrarPortal.KFINTECH: "https://ris.kfintech.com/ipostatus/",
            RegistrarPortal.MAASHITLA: "https://www.maashitla.com/allotment-status/public-issues",
            RegistrarPortal.CAMEO: "https://ipo.cameoindia.com/",
        }.get(self)

    @classmethod
    def from_name(cls, name: str | None) -> RegistrarPortal:
        if not name:
            return cls.UNKNOWN
        n = name.lower()
        if "bigshare" in n:
            return cls.BIGSHARE
        if "link" in n and "intime" in n:
            return cls.LINKINTIME
        if "kfin" in n or "karvy" in n:
            return cls.KFINTECH
        if "maashitla" in n:
            return cls.MAASHITLA
        if "cameo" in n:
            return cls.CAMEO
        return cls.UNKNOWN


class AllotmentService:
    def __init__(self, db: Session) -> None:
        self._db = db

    def check(self, req: AllotmentRequest) -> AllotmentResult:
        ipo = self._resolve(req.ipo_id)
        if not ipo:
            return AllotmentResult(
                outcome=AllotmentOutcome.not_found,
                message=f"IPO not found for id/slug: {req.ipo_id}",
            )

        portal = RegistrarPortal.from_name(ipo.registrar)
        company = ipo.company_name

        url = portal.status_url
        if not url:
            return AllotmentResult(
                outcome=AllotmentOutcome.error,
                company_name=company,
                registrar=portal.value,
                message="No known allotment portal for this registrar.",
            )
        return AllotmentResult.manual(company, portal.value, url)

    def _resolve(self, id_or_slug: str) -> Ipo | None:
        try:
            uid = UUID(id_or_slug)
            return self._db.get(Ipo, uid)
        except ValueError:
            return self._db.scalar(select(Ipo).where(Ipo.source_slug == id_or_slug))
