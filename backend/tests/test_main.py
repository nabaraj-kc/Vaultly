import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.services.extractor import ExtractorService
from app.services.ai import AIService

client = TestClient(app)

def test_health_check():
    """Verify health endpoint works and reports server status."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "online"
    assert "limits_configured" in data

def test_local_mock_ai():
    """Test AI prompt formatting and mock response fallback."""
    summary = AIService._generate_mock_output("summarize", "This is some test content about Vaultly.")
    assert "Executive Summary" in summary
    assert "MOCK DEMO MODE" in summary

    proposal = AIService._generate_mock_output("proposal", "Client project notes.")
    assert "Business Proposal" in proposal

    insights = AIService._generate_mock_output("insights", "Vaultly startup pitch.")
    assert "CARD 1" in insights

def test_extractor_txt():
    """Verify the extractor utility parses TXT payloads correctly."""
    txt_bytes = b"Hello, Vaultly is awesome!"
    parsed = ExtractorService.extract_text_from_bytes(txt_bytes, "test.txt")
    assert parsed == "Hello, Vaultly is awesome!"

def test_extractor_unsupported():
    """Verify the extractor throws error on execution formats."""
    with pytest.raises(ValueError, match="Unsupported file format"):
        ExtractorService.extract_text_from_bytes(b"MZ...", "malicious.exe")

def test_api_process_summarize_free():
    """Test that free tier users can request summaries."""
    payload = {
        "text": "This is standard text content.",
        "action": "summarize",
        "user_tier": "free",
        "user_id": "test_user_free"
    }
    response = client.post("/api/ai/process", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["remaining_credits"] == 2

def test_api_process_proposal_free_blocked():
    """Verify free tier users cannot generate business proposals."""
    payload = {
        "text": "This is standard text content.",
        "action": "proposal",
        "user_tier": "free",
        "user_id": "test_user_free_blocked"
    }
    response = client.post("/api/ai/process", json=payload)
    assert response.status_code == 403
    assert "PRO feature" in response.json()["detail"]

def test_api_process_proposal_pro_allowed():
    """Verify PRO tier users can generate business proposals."""
    payload = {
        "text": "This is standard text content.",
        "action": "proposal",
        "user_tier": "pro",
        "user_id": "test_user_pro"
    }
    response = client.post("/api/ai/process", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["remaining_credits"] == 9999
