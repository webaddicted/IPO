#!/usr/bin/env python3
"""One-shot IPO scrape for Render cron (hourly).

Exits 0 on success, 1 on incomplete/failed scrape so Render marks the run.
"""

from __future__ import annotations

import logging
import sys

from app.db.session import SessionLocal
from app.services.scrape_service import ScrapeIncompleteError, run_scrape

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)
log = logging.getLogger(__name__)


def main() -> int:
    log.info("Render cron scrape starting")
    db = SessionLocal()
    try:
        counts = run_scrape(db)
        log.info(
            "Scrape finished — list=%s subscription=%s details=%s gmp=%s",
            counts["listUpserted"],
            counts["subscriptionUpdated"],
            counts["detailsUpdated"],
            counts["gmpUpdated"],
        )
        return 0
    except ScrapeIncompleteError as exc:
        log.error("Scrape incomplete: %s", "; ".join(exc.issues))
        return 1
    except Exception:
        log.exception("Scrape failed")
        return 1
    finally:
        db.close()


if __name__ == "__main__":
    sys.exit(main())
