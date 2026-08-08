import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import ai, fallback
from app.config import settings

app = FastAPI(
    title="Vaultly AI",
    description="Selective backend engine for Hybrid File Intelligence Platform (Vaultly)",
    version="1.0.0"
)

# CORS Setup: Allow local Flutter web builds, simulator requests, and mobile networks
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Attach routes
app.include_router(ai.router)
app.include_router(fallback.router)

@app.get("/")
def health_check():
    """Health status and metadata endpoint."""
    return {
        "status": "online",
        "app": "Vaultly Backend Service",
        "limits_configured": settings.FREE_DAILY_LIMIT,
        "gemini_api_configured": settings.GEMINI_API_KEY != "",
        "openai_api_configured": settings.OPENAI_API_KEY != ""
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host=settings.HOST, port=settings.PORT, reload=True)
