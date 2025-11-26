from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Dict, Any, List
from services.chat_service import ChatService, PreferencesService
from config import get_settings
import uvicorn

settings = get_settings()
app = FastAPI(title="Browsing Companion AI Service", version="1.0.0")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify actual origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
chat_service = ChatService()
preferences_service = PreferencesService()


# Request/Response Models
class ChatRequest(BaseModel):
    user_id: str
    message: str
    dom_snapshot: Optional[Dict[str, Any]] = None
    session_id: Optional[str] = None


class ChatResponse(BaseModel):
    response: str
    session_id: str
    timestamp: str
    filters: Optional[Dict[str, Any]] = None


class PreferencesRequest(BaseModel):
    is_b2b: bool = False
    preferred_categories: List[str] = []
    hidden_categories: List[str] = []


class PreferencesResponse(BaseModel):
    userId: str
    is_b2b: bool
    preferred_categories: List[str]
    hidden_categories: List[str]


# API Endpoints
@app.get("/")
async def root():
    return {
        "service": "Browsing Companion AI Service",
        "version": "1.0.0",
        "status": "healthy"
    }


@app.get("/health")
async def health():
    return {"status": "healthy"}


@app.post("/process-chat", response_model=ChatResponse)
async def process_chat(request: ChatRequest):
    """
    Process a chat message with optional DOM snapshot context.
    
    The DOM snapshot should contain:
    - visible_products: List of products visible in viewport
    - page_url: Current page URL
    - timestamp: Snapshot timestamp
    """
    try:
        result = await chat_service.process_chat(
            user_id=request.user_id,
            message=request.message,
            dom_snapshot=request.dom_snapshot,
            session_id=request.session_id
        )
        return ChatResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/preferences/{user_id}", response_model=PreferencesResponse)
async def get_preferences(user_id: str):
    """Get user preferences"""
    try:
        preferences = await preferences_service.get_preferences(user_id)
        return PreferencesResponse(**preferences)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/preferences/{user_id}", response_model=PreferencesResponse)
async def update_preferences(user_id: str, preferences: PreferencesRequest):
    """Update user preferences"""
    try:
        result = await preferences_service.update_preferences(
            user_id,
            preferences.dict()
        )
        return PreferencesResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/analyze-preferences")
async def analyze_preferences(request: Dict[str, Any]):
    """
    Analyze user behavior and suggest preference updates.
    This is a placeholder for future ML-based preference learning.
    """
    return {
        "message": "Preference analysis not yet implemented",
        "suggestions": []
    }


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=settings.service_port,
        reload=settings.environment == "development"
    )
