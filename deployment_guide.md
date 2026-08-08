# Vaultly - Deployment and Run Guide

This guide outlines how to run, test, and deploy the hybrid local-first document intelligence platform **Vaultly**.

---

## Architecture Context

Vaultly leverages a **Hybrid Model**:
- **Device-First**: Whenever possible, text extraction (from PDF, TXT) is executed natively on the Flutter client. Previews are instant and run offline.
- **On-Demand Backend**: The FastAPI backend is queried only when the user requests an AI generation action (Summarize, Proposal, Insights) or if local extraction fails (compressed PDF streams, DOCX files).

---

## Setup & Local Development

### 1. Requirements
- **Python**: v3.9+ (v3.14.5 recommended, available via `py`)
- **Flutter**: v3.0+ (with Dart v3.0+)

### 2. Backend Setup
1. Open a terminal in the `/backend` folder.
2. Install Python dependencies:
   ```bash
   py -m pip install -r requirements.txt
   ```
3. Set your environment variables in a `.env` file (copied from `.env.example`):
   ```ini
   PORT=8000
   HOST=0.0.0.0
   GEMINI_API_KEY=your_gemini_api_key_here
   ```
4. Start the FastAPI development server:
   ```bash
   py app/main.py
   ```
   The backend will start running at `http://localhost:8000`. You can access interactive OpenAPI documentation at `http://localhost:8000/docs`.

### 3. Frontend Setup
1. Navigate to the `/frontend` directory.
2. Fetch package dependencies:
   ```bash
   flutter pub get
   ```
3. Launch the app in your target mobile emulator or browser:
   ```bash
   flutter run
   ```
   *Note: If testing on an Android Emulator, ensure the API URL is set to `http://10.0.2.2:8000` (available in Settings). If testing on iOS, use your local machine's IP address (e.g. `http://192.168.x.x:8000`).*

---

## Production Deployment

### 1. Backend Containerization (Docker)
The backend is Dockerized using a lightweight multi-stage configuration. To build and run:

1. Build the production Docker image:
   ```bash
   docker build -t vaultly-backend:latest ./backend
   ```
2. Spin up the container, passing in your LLM credentials:
   ```bash
   docker run -d -p 8000:8000 -e GEMINI_API_KEY="your_api_key" vaultly-backend:latest
   ```

### 2. Cloud Server Hosting (AWS, GCP, Render)
You can deploy the Docker container to platforms like:
- **Render**: Deploy directly from GitHub using a Web Service instance.
- **GCP Cloud Run**: Fully managed serverless platform that automatically scales container requests to zero.
- **AWS ECS / Fargate**: Enterprise-grade container orchestration.

Ensure a reverse proxy (such as Nginx or Cloudflare) is configured to handle:
- HTTPS termination.
- Strict request size limitations (recommended: 10MB).
- DDoS and rate-limiting rules.

### 3. Frontend compilation (Play Store / App Store ready)
To build release bundles for distribution:

- **Android**:
  ```bash
  flutter build appbundle
  ```
- **iOS**:
  ```bash
  flutter build ipa
  ```
