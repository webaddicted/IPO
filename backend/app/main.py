"""FastAPI application entry point."""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError

from app.api.routes import allotment, health, ipos, scrape
from app.config import get_settings
from app.db.session import check_db_connection

logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI):
    settings = get_settings()
    host_hint = settings.sqlalchemy_url.split("@")[-1].split("/")[0] if "@" in settings.sqlalchemy_url else "configured"
    log.info("Database target: %s (pooler=%s)", host_hint, settings.uses_supabase_pooler)
    try:
        check_db_connection()
        log.info("Database connection OK")
    except Exception:
        log.exception(
            "Database connection FAILED at startup — check SUPABASE_DB_* or DATABASE_URL on Render"
        )
    yield


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title="IPO Tracker API",
        version="1.0.0",
        lifespan=lifespan,
    )

    origins = settings.cors_origin_list
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins if "*" not in origins else ["*"],
        allow_credentials=True,
        allow_methods=["GET", "POST", "OPTIONS"],
        allow_headers=["*"],
    )

    @app.exception_handler(ValueError)
    async def value_error_handler(_: Request, exc: ValueError) -> JSONResponse:
        return JSONResponse(status_code=400, content={"error": str(exc)})

    @app.exception_handler(SQLAlchemyError)
    async def sqlalchemy_error_handler(_: Request, exc: SQLAlchemyError) -> JSONResponse:
        log.exception("Database error")
        detail = str(exc.orig) if getattr(exc, "orig", None) else str(exc)
        if "does not exist" in detail.lower():
            return JSONResponse(
                status_code=503,
                content={
                    "error": "database_schema_missing",
                    "message": "IPO tables not found. Run supabase/migrations on your Supabase project.",
                    "detail": detail,
                },
            )
        return JSONResponse(
            status_code=503,
            content={
                "error": "database_unavailable",
                "message": "Cannot reach Supabase Postgres. Check SUPABASE_DB_URL (pooler port 6543), user, and password on Render.",
                "detail": detail,
            },
        )

    @app.exception_handler(Exception)
    async def unhandled_error_handler(_: Request, exc: Exception) -> JSONResponse:
        log.exception("Unhandled error")
        return JSONResponse(
            status_code=500,
            content={
                "error": "internal_error",
                "message": str(exc),
            },
        )

    app.include_router(health.router)
    app.include_router(ipos.router)
    app.include_router(allotment.router)
    app.include_router(scrape.router)
    return app


app = create_app()
