"""Health check."""

from fastapi import APIRouter
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from app.db.session import engine

router = APIRouter(tags=["health"])


@router.get("/health")
def health() -> dict[str, str]:
    return {"status": "UP", "service": "ipo-tracker-backend"}


@router.get("/health/db")
def health_db() -> dict[str, object]:
    """Verify Supabase Postgres connectivity (use after Render deploy)."""
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
            tables = conn.execute(
                text(
                    "SELECT to_regclass('public.ipo_ipos') IS NOT NULL AS ipo_tables_ready"
                )
            ).scalar()
        return {
            "status": "UP",
            "database": "connected",
            "ipoTablesReady": bool(tables),
        }
    except SQLAlchemyError as exc:
        detail = str(exc.orig) if getattr(exc, "orig", None) else str(exc)
        return {
            "status": "DOWN",
            "database": "error",
            "message": detail,
        }
