# Vaultly 🔒📱

> **Cross-Platform Encrypted Vault Application**  
> *Built with Flutter for Mobile/Desktop, FastAPI for Backend Encryption Orchestration, and Docker for Secure Container Deployment.*

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.111.0-009688?style=flat&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED?style=flat&logo=docker&logoColor=white)](https://docker.com)

---

## 💡 Overview

**Vaultly** is a personal privacy and data security application providing client-side and server-assisted encryption for sensitive documents, notes, and credentials across Mobile and Desktop platforms.

---

## 🚀 Setup

```bash
# Backend Execution
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn main:app --reload

# Frontend Launch
cd ../frontend
flutter run
```
