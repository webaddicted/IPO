"""Runtime configuration from environment / .env."""

from __future__ import annotations

from functools import lru_cache
from urllib.parse import quote_plus, parse_qs, urlencode, urlparse, urlunparse

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


def _strip_quotes(value: str | None) -> str | None:
    if value is None:
        return None
    s = value.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in "\"'":
        return s[1:-1]
    return s


def jdbc_to_sqlalchemy_url(jdbc_url: str, user: str, password: str) -> str:
    """Convert a JDBC Postgres URL to SQLAlchemy psycopg2 form."""
    url = jdbc_url.strip()
    if url.startswith("jdbc:"):
        url = url[5:]
    parsed = urlparse(url)
    netloc = parsed.hostname or ""
    if parsed.port:
        netloc = f"{netloc}:{parsed.port}"
    if user:
        creds = quote_plus(user)
        if password:
            creds = f"{creds}:{quote_plus(password)}"
        netloc = f"{creds}@{netloc}"
    path = parsed.path or "/postgres"
    params = parse_qs(parsed.query, keep_blank_values=True)
    params.pop("prepareThreshold", None)
    if "sslmode" not in params:
        params["sslmode"] = ["require"]
    query = urlencode({k: v[0] for k, v in params.items()})
    return urlunparse(("postgresql+psycopg2", netloc, path, "", query, ""))


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    port: int = Field(default=8081, alias="PORT")
    database_url: str | None = Field(default=None, alias="DATABASE_URL")
    supabase_db_url: str = Field(
        default="jdbc:postgresql://localhost:5432/postgres?sslmode=require",
        alias="SUPABASE_DB_URL",
    )
    supabase_db_user: str = Field(default="postgres", alias="SUPABASE_DB_USER")
    supabase_db_password: str = Field(default="", alias="SUPABASE_DB_PASSWORD")

    scheduler_enabled: bool = Field(default=True, alias="SCHEDULER_ENABLED")
    scheduler_run_on_start: bool = Field(default=False, alias="SCHEDULER_RUN_ON_START")
    scraper_interval_minutes: int = Field(default=60, alias="SCRAPER_INTERVAL_MINUTES")
    scraper_user_agent: str = Field(
        default=(
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
            "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
        ),
        alias="SCRAPER_USER_AGENT",
    )
    scraper_timeout_ms: int = Field(default=15000, alias="SCRAPER_TIMEOUT_MS")
    scraper_polite_delay_ms: int = Field(default=2500, alias="SCRAPER_POLITE_DELAY_MS")
    scraper_list_fixed_rate_ms: int = Field(
        default=3_600_000, alias="SCRAPER_LIST_FIXED_RATE_MS"
    )

    cors_origins: str = Field(default="*", alias="CORS_ORIGINS")

    @field_validator("database_url", mode="before")
    @classmethod
    def normalize_database_url(cls, value: object) -> object:
        if isinstance(value, str):
            stripped = _strip_quotes(value)
            return None if not stripped else stripped
        return value

    @field_validator("supabase_db_url", "supabase_db_user", "supabase_db_password", mode="before")
    @classmethod
    def strip_env_quotes(cls, value: object) -> object:
        if isinstance(value, str):
            return _strip_quotes(value) or value
        return value

    @property
    def scraper_interval_seconds(self) -> int:
        """Scrape interval in seconds (min 60s). Prefers SCRAPER_INTERVAL_MINUTES."""
        minutes = self.scraper_interval_minutes
        if minutes > 0:
            return max(minutes * 60, 60)
        return max(self.scraper_list_fixed_rate_ms // 1000, 60)

    @property
    def sqlalchemy_url(self) -> str:
        if self.database_url:
            url = self.database_url
            if url.startswith("postgresql://") and "+psycopg2" not in url:
                url = url.replace("postgresql://", "postgresql+psycopg2://", 1)
            return url
        return jdbc_to_sqlalchemy_url(
            self.supabase_db_url,
            self.supabase_db_user,
            self.supabase_db_password,
        )

    @property
    def uses_supabase_pooler(self) -> bool:
        return "pooler.supabase.com" in self.sqlalchemy_url

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
