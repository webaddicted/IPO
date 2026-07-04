"""On-demand scrape API — one GET endpoint to pull all IPO data."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.services.scrape_service import ScrapeIncompleteError, run_scrape

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

    return {
        "status": "ok",
        **counts,
    }
