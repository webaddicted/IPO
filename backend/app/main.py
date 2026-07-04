"""FastAPI application entry point."""

from __future__ import annotations

import logging

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.routes import allotment, health, ipos, scrape
from app.config import get_settings

logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title="IPO Tracker API",
        version="1.0.0",
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

    app.include_router(health.router)
    app.include_router(ipos.router)
    app.include_router(allotment.router)
    app.include_router(scrape.router)
    return app


app = create_app()
