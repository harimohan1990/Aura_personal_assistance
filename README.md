# Aura_personal_assistance

**AURA** is an Enterprise Executive AI Desktop & Voice Assistant built natively for macOS with Swift/SwiftUI and Python (FastAPI).

## ✨ Features

- **Executive Daily Briefing**: Automated morning brief with strategic proverbs, P0 critical deliverable counts, and voice readouts.
- **Priority Deliverables Matrix**: Eisenhower-inspired task board (P0 Critical, P1 Strategic, P2 Operational, P3 Delegated) with persistent storage and voice creation.
- **AI Executive Email Studio**: Generates 5 tone-tailored executive communications with 1-click clipboard copy and direct macOS Mail pre-fill.
- **Meeting & Agenda Architect**: Generates time-blocked 15m, 30m, and 60m agendas with DRI decision gates and Apple Notes export.
- **Financial KPI Engine**: Real-time runway/burn rate calculators, LTV:CAC unit economics, and MRR/ARR velocity trackers.
- **Hands-Free Voice & System Control**: Continuous accessibility speech recognition, app launchers for 500+ apps, AppleScript automations, MapKit routing, and system telemetry.

## 🛠️ Tech Stack

- **Native Desktop Client**: Swift 6, SwiftUI, AppKit, AVFoundation, Speech Framework, MapKit
- **Backend API**: Python 3, FastAPI, Uvicorn, AppleScript
- **Platform**: macOS 14.0+ Sonoma / Sequoia

## 🚀 Getting Started

### 1. Build Native macOS App
```bash
cd AURA
bash build_app.sh
```

### 2. Start Python Backend (Optional)
```bash
python3 server.py
```
