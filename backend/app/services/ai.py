import json
import logging
from app.config import settings

# Attempt to configure google-generativeai
GEMINI_AVAILABLE = False
try:
    import google.generativeai as genai
    if settings.GEMINI_API_KEY:
        genai.configure(api_key=settings.GEMINI_API_KEY)
        GEMINI_AVAILABLE = True
except Exception as e:
    logging.warning(f"Failed to load or configure google-generativeai: {e}")

# Attempt to configure OpenAI
OPENAI_AVAILABLE = False
try:
    import httpx
    if settings.OPENAI_API_KEY:
        OPENAI_AVAILABLE = True
except Exception as e:
    logging.warning(f"Failed to load openai config: {e}")

class AIService:
    @staticmethod
    def get_prompt(action: str, text: str) -> str:
        """Returns the specific prompt based on user task action."""
        if action == "summarize":
            return (
                "You are an expert Document Analyst. Analyze the following text and generate a structured "
                "executive summary.\n\n"
                "Provide:\n"
                "- **Overall Executive Summary**: A concise paragraph capturing the essence.\n"
                "- **Key Takeaways & Points**: 4-6 bullet points summarizing core arguments or facts.\n"
                "- **Contextual Metadata**: Extract any names, organizations, dates, or key metrics found.\n\n"
                f"Source Document Text:\n\"\"\"\n{text}\n\"\"\"\n"
            )
        elif action == "proposal":
            return (
                "You are a professional Business Consultant and Startup CTO. Transform the following project notes/text "
                "into a structured, client-ready business proposal.\n\n"
                "Provide the following sections:\n"
                "- **1. Executive Summary**: High-level pitch.\n"
                "- **2. Problem Statement**: What pain point is being solved.\n"
                "- **3. Proposed Solution**: Technical/operational solution.\n"
                "- **4. Scope of Work & Deliverables**: Clear milestones.\n"
                "- **5. Budget & Pricing**: Estimated costs and options.\n"
                "- **6. Next Steps**: How to sign off and start.\n\n"
                f"Source Material:\n\"\"\"\n{text}\n\"\"\"\n"
            )
        elif action == "insights":
            return (
                "You are a viral Social Media Creator. Extract 3 distinct 'Insight Cards' from the text below. "
                "Each card must be independent, compact (under 280 characters if possible), and fully optimized for "
                "copying and sharing to platforms like LinkedIn, Twitter/X, or WhatsApp.\n\n"
                "Format exactly as:\n"
                "CARD 1:\n"
                "[Catchy Title]\n"
                "[Core insight explanation with bullet points or key stats]\n"
                "[Hashtags]\n\n"
                "CARD 2:\n...\n\n"
                "CARD 3:\n...\n\n"
                f"Source Document:\n\"\"\"\n{text}\n\"\"\"\n"
            )
        elif action == "chat":
            return text
        else:
            return f"Extract key insights from the following text:\n{text}"

    @classmethod
    async def process_text(cls, text: str, action: str) -> str:
        """Dispatches request to Gemini/OpenAI, falling back to Mock engine if keys are absent."""
        if not text.strip():
            return "Error: Document text is empty."

        prompt = cls.get_prompt(action, text)

        # 1. Try Gemini with auto-failover routing
        if GEMINI_AVAILABLE:
            models_to_try = ["gemini-2.5-flash", "gemini-1.5-flash", "gemini-2.5-pro", "gemini-1.5-pro"]
            for model_name in models_to_try:
                try:
                    logging.info(f"Attempting AI processing with Gemini model: {model_name}")
                    model = genai.GenerativeModel(model_name)
                    response = model.generate_content(prompt)
                    if response and response.text:
                        return response.text
                except Exception as e:
                    logging.error(f"Gemini model {model_name} failed: {e}. Trying next model...")
            logging.error("All Gemini model attempts exhausted. Falling back...")

        # 2. Try OpenAI via REST HTTP request to minimize package imports
        if OPENAI_AVAILABLE and settings.OPENAI_API_KEY:
            try:
                async with httpx.AsyncClient() as client:
                    response = await client.post(
                        "https://api.openai.com/v1/chat/completions",
                        headers={
                            "Authorization": f"Bearer {settings.OPENAI_API_KEY}",
                            "Content-Type": "application/json",
                        },
                        json={
                            "model": "gpt-4o-mini",
                            "messages": [
                                {"role": "system", "content": "You are a professional file intelligence assistant."},
                                {"role": "user", "content": prompt}
                            ],
                            "temperature": 0.2
                        },
                        timeout=30.0
                    )
                    if response.status_code == 200:
                        data = response.json()
                        return data["choices"][0]["message"]["content"]
            except Exception as e:
                logging.error(f"OpenAI REST API execution error: {e}. Falling back...")

        # 3. Intelligent Mock Fallback (Useful for developer evaluation without keys)
        return cls._generate_mock_output(action, text)

    @staticmethod
    def _generate_mock_output(action: str, text: str) -> str:
        """Generates contextual local summaries without calling external APIs."""
        snippet = text[:150] + "..." if len(text) > 150 else text
        
        if action == "summarize":
            return (
                f"# Executive Summary (MOCK DEMO MODE)\n"
                f"This document describes topics related to: *{snippet}*\n\n"
                f"### Key Takeaways\n"
                f"- **Core Theme**: High-speed offline-first document parsing and text conversion.\n"
                f"- **Local Extraction**: TXT and PDF parsed natively on the device.\n"
                f"- **Scalability**: Backend resources only query LLMs on-demand.\n"
                f"- **Freemium Tier**: Daily limits are simulated to manage costs.\n\n"
                f"### Extracted Entities\n"
                f"- **Entity/Concept**: File intelligence system\n"
                f"- **Context**: Mobile productivity application\n"
                f"\n*Note: To replace this mock output, please set a valid `GEMINI_API_KEY` in the backend `.env` file.*"
            )
        elif action == "proposal":
            return (
                f"# Business Proposal: Project Vaultly Integration (MOCK)\n\n"
                f"## 1. Executive Summary\n"
                f"A plan to build a hybrid productivity app based on the text: *{snippet}*.\n\n"
                f"## 2. Problem Statement\n"
                f"Modern professionals are overloaded with files (PDFs, PPTXs, DOCXs) and waste hours reading long reports on mobile screens.\n\n"
                f"## 3. Proposed Solution\n"
                f"Introduce Vaultly's hybrid local processing model that parses documents locally, sending only clean text directly to the AI service.\n\n"
                f"## 4. Scope of Work\n"
                f"- Phase 1: Local PDF & TXT support with AI summaries.\n"
                f"- Phase 2: Shareable Insight Cards & Proposal builder.\n\n"
                f"## 5. Budget & Estimate\n"
                f"- Setup: $0 (Uses Gemini Flash pricing or local Mock fallback).\n"
                f"- Timeline: 2 weeks.\n\n"
                f"\n*Note: To replace this mock output, please set a valid `GEMINI_API_KEY` in the backend `.env` file.*"
            )
        elif action == "insights":
            return (
                f"CARD 1:\n"
                f"💡 Turn Files to Insight\n"
                f"Stop reading long documents on tiny screens. Vaultly extracts, summarizes, and generates actionable outputs. #Productivity #AI #Startup\n\n"
                f"CARD 2:\n"
                f"⚡ Hybrid Mobile Architecture\n"
                f"Maximize performance by parsing text locally on your device and only routing tiny raw text payloads to the cloud. #SoftwareArchitecture #Flutter #FastAPI\n\n"
                f"CARD 3:\n"
                f"💰 Scalable Freemium\n"
                f"Vaultly runs offline for basic features, and charges for advanced proposal generation. Clean, fast, and monetized. #MobileApps #SaaS #CTO\n\n"
                f"*Note: To replace this mock output, please set a valid `GEMINI_API_KEY` in the backend `.env` file.*"
            )
        return f"### Document Analysis\n{snippet}"
