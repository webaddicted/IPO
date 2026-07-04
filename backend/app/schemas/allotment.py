"""Allotment request/response schemas."""

from __future__ import annotations

from enum import Enum

from pydantic import Field, field_validator

from app.schemas.base import CamelModel


class AllotmentOutcome(str, Enum):
    allotted = "ALLOTTED"
    not_allotted = "NOT_ALLOTTED"
    not_found = "NOT_FOUND"
    manual_check_required = "MANUAL_CHECK_REQUIRED"
    error = "ERROR"


class AllotmentRequest(CamelModel):
    ipo_id: str = Field(min_length=1)
    pan: str
    application_number: str | None = None

    @field_validator("pan")
    @classmethod
    def validate_pan(cls, v: str) -> str:
        import re

        if not re.fullmatch(r"^[A-Za-z]{5}[0-9]{4}[A-Za-z]$", v):
            raise ValueError("Invalid PAN format")
        return v.upper()


class AllotmentResult(CamelModel):
    outcome: AllotmentOutcome
    company_name: str | None = None
    registrar: str | None = None
    manual_check_url: str | None = None
    shares_applied: int | None = None
    shares_allotted: int | None = None
    message: str | None = None

    @classmethod
    def manual(cls, company: str, registrar: str, url: str) -> AllotmentResult:
        return cls(
            outcome=AllotmentOutcome.manual_check_required,
            company_name=company,
            registrar=registrar,
            manual_check_url=url,
            message=(
                "Automated check is unavailable for this registrar (captcha-protected). "
                "Tap to verify on the official portal."
            ),
        )
