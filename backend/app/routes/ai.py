from fastapi import APIRouter, HTTPException, status
from app.schemas import TextProcessRequest, AIOutputResponse
from app.services.ai import AIService
from app.config import settings
from datetime import datetime, date
from typing import Dict, List

router = APIRouter(prefix="/api/ai", tags=["AI Processing"])

# Lightweight in-memory usage tracker for freemium simulation (resets daily)
# Structure: { user_id: { date: count } }
usage_db: Dict[str, Dict[date, int]] = {}

def get_remaining_credits(user_id: str, tier: str) -> int:
    """Calculates remaining free actions. PRO users get effectively infinite credits."""
    if tier.lower() == "pro":
        return 9999
        
    today = datetime.now().date()
    user_usage = usage_db.setdefault(user_id, {})
    current_count = user_usage.get(today, 0)
    
    return max(0, settings.FREE_DAILY_LIMIT - current_count)

def record_usage(user_id: str, tier: str):
    """Increments the daily request counter for a user."""
    if tier.lower() == "pro":
        return
        
    today = datetime.now().date()
    user_usage = usage_db.setdefault(user_id, {})
    user_usage[today] = user_usage.get(today, 0) + 1

@router.post("/process", response_model=AIOutputResponse)
async def process_text(payload: TextProcessRequest):
    """Processes extracted text directly via LLM prompt templates."""
    # Limits and feature restrictions are disabled for testing.
    try:
        # 3. Call AI Service
        result_text = await AIService.process_text(payload.text, payload.action)
        
        # 4. Deduct credit/record usage
        record_usage(payload.user_id, payload.user_tier)
        updated_remaining = get_remaining_credits(payload.user_id, payload.user_tier)
        
        return AIOutputResponse(
            status="success",
            result=result_text,
            remaining_credits=updated_remaining
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI Processing failed: {str(e)}"
        )
