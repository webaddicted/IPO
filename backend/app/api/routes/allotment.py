"""Allotment endpoint."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.allotment import AllotmentRequest, AllotmentResult
from app.services.allotment_service import AllotmentService

router = APIRouter(prefix="/api/v1", tags=["allotment"])


@router.post("/allotment", response_model=AllotmentResult)
def check_allotment(
    request: AllotmentRequest,
    db: Session = Depends(get_db),
) -> AllotmentResult:
    return AllotmentService(db).check(request)
