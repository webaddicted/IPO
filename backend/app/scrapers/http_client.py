"""Shared HTTP client for chittorgarh / investorgain JSON APIs."""

from __future__ import annotations

import logging
import time
from datetime import date

import httpx

from app.config import Settings

log = logging.getLogger(__name__)


class ScraperHttpClient:
    CHITTORGARH = "https://www.chittorgarh.com"
    CHITTORGARH_API = "https://webnodejs.chittorgarh.com"
    INVESTOR_GAIN_API = "https://webnodejs.investorgain.com"

    def __init__(self, settings: Settings) -> None:
        self._ua = settings.scraper_user_agent
        self._timeout = settings.scraper_timeout_ms / 1000.0

    def _fy_parts(self) -> tuple[int, int, str]:
        now = date.today()
        year = now.year
        month = now.month
        fy_start = year if month >= 4 else year - 1
        fy = f"{fy_start}-{(fy_start + 1) % 100:02d}"
        return month, year, fy

    def fetch_chittorgarh_report(self, report_id: int, parameter: str) -> dict:
        return self.fetch_chittorgarh_report_search(report_id, parameter, "")

    def fetch_chittorgarh_report_search(
        self, report_id: int, parameter: str, search: str
    ) -> dict:
        month, year, fy = self._fy_parts()
        q = search or ""
        url = (
            f"{self.CHITTORGARH_API}/cloud/report/data-read/"
            f"{report_id}/1/{month}/{year}/{fy}/0/{parameter}?search={q}&v=1"
        )
        return self.fetch_json(url, self.CHITTORGARH)

    def fetch_ipo_detail(self, chittorgarh_id: int) -> dict:
        url = f"{self.CHITTORGARH_API}/cloud/ipo/detail-read/{chittorgarh_id}/"
        return self.fetch_json(url, self.CHITTORGARH)

    def fetch_investorgain_report(
        self, report_id: int, parameter: str, search: str = ""
    ) -> dict:
        month, year, fy = self._fy_parts()
        q = search or ""
        url = (
            f"{self.INVESTOR_GAIN_API}/cloud/report/data-read/"
            f"{report_id}/1/{month}/{year}/{fy}/0/{parameter}?search={q}&v=1"
        )
        return self.fetch_json(url, "https://www.investorgain.com")

    def fetch_json(self, url: str, referer: str) -> dict:
        headers = {
            "User-Agent": self._ua,
            "Referer": f"{referer}/",
            "Accept": "application/json",
        }
        last_exc: Exception | None = None
        for attempt in range(1, 4):
            try:
                with httpx.Client(timeout=self._timeout) as client:
                    resp = client.get(url, headers=headers)
                    resp.raise_for_status()
                    return resp.json()
            except (httpx.HTTPError, ValueError) as exc:
                last_exc = exc
                if attempt < 3:
                    wait = attempt * 1.5
                    log.warning("Fetch failed (attempt %s/3) %s: %s", attempt, url, exc)
                    time.sleep(wait)
        raise last_exc  # type: ignore[misc]
