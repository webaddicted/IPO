"""Tests for scraper scheduler."""

from unittest.mock import MagicMock, patch

from app.config import Settings
from app.scheduler import create_scheduler, run_scheduled_scrape


def test_scraper_interval_seconds_from_minutes():
    s = Settings(SCRAPER_INTERVAL_MINUTES=30)
    assert s.scraper_interval_seconds == 1800


def test_scraper_interval_seconds_minimum():
    s = Settings(SCRAPER_INTERVAL_MINUTES=0)
    assert s.scraper_interval_seconds >= 60


@patch("app.scheduler.run_scrape")
@patch("app.scheduler.SessionLocal")
def test_run_scheduled_scrape_calls_run_scrape(mock_session_local, mock_run_scrape):
    db = MagicMock()
    mock_session_local.return_value = db
    mock_run_scrape.return_value = {
        "listUpserted": 10,
        "subscriptionUpdated": 10,
        "detailsUpdated": 10,
        "gmpUpdated": 2,
    }

    run_scheduled_scrape()

    mock_run_scrape.assert_called_once_with(db)
    db.close.assert_called_once()


def test_create_scheduler_registers_job():
    settings = Settings(SCHEDULER_ENABLED=True, SCRAPER_INTERVAL_MINUTES=60)
    scheduler = create_scheduler(settings)
    assert scheduler.get_job("ipo_full_scrape") is not None
