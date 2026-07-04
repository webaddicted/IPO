"""Tests for scrape service."""

from unittest.mock import MagicMock, patch

import pytest

from app.services.scrape_service import ScrapeIncompleteError, run_scrape, validate_scrape


@patch("app.services.scrape_service.validate_scrape", return_value=[])
@patch("app.services.scrape_service._run_once")
def test_run_scrape_success(mock_run_once, _mock_validate):
    mock_run_once.return_value = {
        "listUpserted": 5,
        "subscriptionUpdated": 5,
        "detailsUpdated": 5,
        "gmpUpdated": 2,
    }
    result = run_scrape(MagicMock())
    assert result["listUpserted"] == 5
    mock_run_once.assert_called_once()


@patch("app.services.scrape_service.validate_scrape", return_value=["details scraped 0/5"])
@patch("app.services.scrape_service._run_once")
def test_run_scrape_raises_when_incomplete(mock_run_once, _mock_validate):
    mock_run_once.return_value = {
        "listUpserted": 5,
        "subscriptionUpdated": 5,
        "detailsUpdated": 0,
        "gmpUpdated": 0,
    }
    with pytest.raises(ScrapeIncompleteError) as exc:
        run_scrape(MagicMock())
    assert exc.value.issues == ["details scraped 0/5"]
    assert mock_run_once.call_count == 3
