"""Standalone scraper scheduler process.

Run separately from the API server:
  ./run_scheduler.sh

Uses the same scrape catalog as GET /api/v1/scrape and stores to Supabase.
"""

from __future__ import annotations

import logging
import sys

from app.config import get_settings
from app.scheduler import create_scheduler, run_scheduled_scrape

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)
log = logging.getLogger(__name__)


def main() -> None:
    settings = get_settings()
    if not settings.scheduler_enabled:
        log.info("SCHEDULER_ENABLED=false — scheduler not started")
        sys.exit(0)

    interval_min = settings.scraper_interval_minutes
    log.info(
        "IPO scraper scheduler starting — interval=%s min, run_on_start=%s",
        interval_min,
        settings.scheduler_run_on_start,
    )

    if settings.scheduler_run_on_start:
        log.info("Running initial scrape on startup")
        run_scheduled_scrape()

    scheduler = create_scheduler(settings)
    try:
        scheduler.start()
    except (KeyboardInterrupt, SystemExit):
        log.info("Scheduler shutting down")
        scheduler.shutdown(wait=False)


if __name__ == "__main__":
    main()
