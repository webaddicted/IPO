"""On-demand scrape API — one GET endpoint to pull all IPO data."""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.services.scrape_service import ScrapeIncompleteError, run_scrape

log = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/v1",
    tags=["scrape"],
)


@router.get("/scrape")
def scrape_data(db: Session = Depends(get_db)) -> dict:
    """
    Scrape chittorgarh.com + investorgain for all IPO data, store in Supabase.

    Returns success only when every IPO has list, subscription, and detail rows.
    """
    try:
        counts = run_scrape(db)
    except ScrapeIncompleteError as exc:
        raise HTTPException(
            status_code=502,
            detail={
                "status": "incomplete",
                "issues": exc.issues,
                **exc.counts,
            },
        ) from exc
    except SQLAlchemyError as exc:
        log.exception("Scrape failed — database error")
        detail = str(exc.orig) if getattr(exc, "orig", None) else str(exc)
        raise HTTPException(
            status_code=503,
            detail={
                "status": "database_error",
                "message": detail,
            },
        ) from exc
    except Exception as exc:
        log.exception("Scrape failed")
        raise HTTPException(
            status_code=500,
            detail={
                "status": "error",
                "message": str(exc),
            },
        ) from exc

    return {
        "status": "ok",
        **counts,
    }
