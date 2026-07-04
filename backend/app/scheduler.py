"""IPO scraper scheduler — uses the same run_scrape logic as GET /api/v1/scrape."""

from __future__ import annotations

import logging

from apscheduler.schedulers.blocking import BlockingScheduler
from apscheduler.triggers.interval import IntervalTrigger

from app.config import Settings
from app.db.session import SessionLocal
from app.services.scrape_service import ScrapeIncompleteError, run_scrape

log = logging.getLogger(__name__)


def run_scheduled_scrape() -> None:
    """Run a full scrape and store results in Supabase."""
    db = SessionLocal()
    try:
        counts = run_scrape(db)
        log.info(
            "Scheduled scrape finished — list=%s subscription=%s details=%s gmp=%s",
            counts["listUpserted"],
            counts["subscriptionUpdated"],
            counts["detailsUpdated"],
            counts["gmpUpdated"],
        )
    except ScrapeIncompleteError as exc:
        log.error("Scheduled scrape incomplete: %s", "; ".join(exc.issues))
    except Exception:
        log.exception("Scheduled scrape failed")
    finally:
        db.close()


def create_scheduler(settings: Settings) -> BlockingScheduler:
    interval_sec = settings.scraper_interval_seconds
    scheduler = BlockingScheduler(timezone="Asia/Kolkata")
    scheduler.add_job(
        run_scheduled_scrape,
        IntervalTrigger(seconds=interval_sec),
        id="ipo_full_scrape",
        replace_existing=True,
        max_instances=1,
        coalesce=True,
    )
    log.info(
        "Scheduler configured — full scrape every %s min (%ss)",
        settings.scraper_interval_minutes,
        interval_sec,
    )
    return scheduler
