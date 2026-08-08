# Project: Vaultly - File Intelligence Platform

## Description
Vaultly is a mobile-first hybrid File Intelligence Platform that allows users to turn files into actionable business assets (Summaries, Proposals, and social shareable Insight Cards) in seconds.

## Technical Architecture (Hybrid Split)

- **Frontend (Flutter)**: Performs client-side PDF/TXT parsing, displays instant previews, handles local file caches, handles state management, and dispatches extracted text payloads to the backend.
- **Backend (FastAPI)**: Lightweight orchestration API layer that connects to Gemini / OpenAI to return structured markdown & JSON actions. Includes a fallback endpoint to parse documents if local extraction fails.

```
+-------------------------------------------------------------+
|                     Flutter Mobile Client                   |
|  - File Picker                                              |
|  - Local PDF/TXT Extractor & Text Previews                  |
|  - Offline Caching & Local State                            |
+------------------------------+------------------------------+
                               |
                   POST /api/ai/process (Extracted Text Only)
                               |
                               v
+-------------------------------------------------------------+
|                     FastAPI Cloud Service                   |
|  - LLM Orchestrator (Gemini / OpenAI prompt templates)      |
|  - Fallback File Parser (when frontend parser fails)        |
+-------------------------------------------------------------+
```

## Branding & Core Theme Tokens
- **Background**: Slate Black `#121214`
- **Surface**: Charcoal Gray `#1E1E24`
- **Primary Accent**: Electric Indigo `#4F46E5`
- **Success Accent**: Neon Mint / Emerald Teal `#10B981`
- **Text Primary**: Off-White `#F3F4F6`
- **Text Secondary**: Muted Lavender `#9CA3AF`
- **Freemium Limit Warning Color**: Crimson Red `#EF4444`

## API Contract

### 1. Process Text
`POST /api/ai/process`
- **Payload**:
  ```json
  {
    "text": "Extracted document text...",
    "action": "summarize" | "proposal" | "insights",
    "user_tier": "free" | "pro"
  }
  ```
- **Response**:
  ```json
  {
    "status": "success",
    "result": "Markdown text output",
    "remaining_credits": 2
  }
  ```

### 2. Fallback File Extraction
`POST /api/files/extract-fallback`
- **Payload**: Form-data containing `file`.
- **Response**:
  ```json
  {
    "status": "success",
    "extracted_text": "Parsed document text..."
  }
  ```
