# Vaultly

Cross-platform application for encrypted file and note storage.

## Overview

Vaultly provides client-side and server-assisted encryption for sensitive documents, notes, and credentials across desktop and mobile platforms.

## Architecture

- Backend: FastAPI service handling authentication, encryption utilities, and file storage logic.
- Frontend: Flutter application targeting Android, iOS, Windows, macOS, and Linux.

## Setup

### Backend Setup

```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload
```

### Frontend Setup

```bash
cd frontend
flutter pub get
flutter run
```
