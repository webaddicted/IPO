"""Scraper orchestration factory."""

from __future__ import annotations

from sqlalchemy.orm import Session

from app.config import Settings, get_settings
from app.scrapers.gmp import GmpScraper
from app.scrapers.http_client import ScraperHttpClient
from app.scrapers.ipo_detail import IpoDetailScraper
from app.scrapers.ipo_list import IpoListScraper
from app.scrapers.subscription import SubscriptionScraper


def build_scrapers(db: Session, settings: Settings | None = None):
    settings = settings or get_settings()
    http = ScraperHttpClient(settings)
    return {
        "list": IpoListScraper(db, http, settings),
        "gmp": GmpScraper(db, http),
        "subscription": SubscriptionScraper(db, http),
        "detail": IpoDetailScraper(db, http, settings),
    }
