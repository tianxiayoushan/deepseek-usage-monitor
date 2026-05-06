# DeepSeek Usage Monitor v0.2.2

A local-only, Nothing-inspired industrial dashboard that monitors your DeepSeek API account balance and usage in real time.

![DeepSeek Usage Monitor Screenshot](./src/assets/hero.png)

---

## Quick Start

### macOS

1. Download or clone this repository.
2. Double-click **`start-mac.command`**.
   - If macOS blocks execution (Gatekeeper), open Terminal and run once:
     ```bash
     chmod +x start-mac.command
     ```
3. The script will automatically install all dependencies on first run (may take a few minutes).
4. Open **http://localhost:5173** in your browser.
5. Click the **⚙ Settings** icon and enter your **DeepSeek API Key**.

> **To stop:** Press `Ctrl+C` in the Terminal window. Both backend and frontend will be shut down cleanly.

---

### Windows

1. Download or clone this repository.
2. Double-click **`start-windows.bat`**.
3. Two separate windows will open:
   - **"DeepSeek Backend"** — FastAPI server on port 8789
   - **"DeepSeek Frontend"** — Vite dev server on port 5173
4. Open **http://localhost:5173** in your browser (it may open automatically).
5. Click the **⚙ Settings** icon and enter your **DeepSeek API Key**.

> **To stop:** Close both the Backend and Frontend windows.

---

### dashboard.html (Launcher Guide)

The file `dashboard.html` in the project root is a **static launcher/help page**.

- Double-click it to open in a browser for setup guidance and quick links.
- It **cannot** start the backend or frontend by itself — use the launch scripts above.
- Use it to quickly access the Dashboard and health check URLs once the app is running.

---

## Prerequisites

| Requirement | Version | Download |
|-------------|---------|----------|
| Node.js | 18+ | https://nodejs.org/ |
| Python | 3.10+ | https://www.python.org/downloads/ |
| DeepSeek API Key | — | https://platform.deepseek.com/ |

---

## Manual Setup (Advanced)

### Backend
```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate.bat
pip install -r requirements.txt
cp .env.example .env
# Edit .env and set DEEPSEEK_API_KEY (optional — can also use Settings panel)
uvicorn main:app --host 127.0.0.1 --port 8789 --reload
```

### Frontend
```bash
npm install
npm run dev   # http://localhost:5173
```

---

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DEEPSEEK_API_KEY` | Optional\* | DeepSeek API key starting with `sk-`. Can also be set via the Settings panel. |
| `INITIAL_TOTAL_CREDIT_CNY` | Optional | Initial credit amount (CNY) for estimating historical spend. Can also be set via Settings. |

\*The API key is required for real balance data. Without it, the dashboard shows mock data.

---

## Total Spend Calculation

DeepSeek `/user/balance` does **not** provide historical spend data.
Total Spend is estimated using:

```
historical_total_spend = initial_total_credit − current_total_balance
```

### Configuration (Settings panel recommended)

**Option 1: Settings Panel** *(no restart needed)*

Click the ⚙ icon → enter **Initial Total Credit** → Save.
Stored in `backend/local_settings.json` (gitignored, local only).

**Option 2: Environment variable**

```
INITIAL_TOTAL_CREDIT_CNY=80.00
```

### When not configured

- Total Spend falls back to mock data (`¥16.58`)
- Settings panel shows a warning
- A `console.warn` is logged (no error thrown)

### ⚠ Estimation Limitations

This is an **estimate only**, not an official DeepSeek invoice. It does not account for:
- Granted/promotional credits expiring
- Refunds or reversals
- Currency changes
- Admin account adjustments

---

## Security

> **⚠ Never commit secrets to GitHub.**

The following files are in `.gitignore` and will **never** be committed:

| File | Contains |
|------|----------|
| `backend/.env` | Your API key (if set via file) |
| `backend/local_settings.json` | API key and credit settings saved via Settings panel |
| `backend/.venv` | Python virtual environment |
| `node_modules` | Frontend dependencies |

**Rules & Privacy:**
- **Local Only**: Your API key is stored only on your machine in `backend/local_settings.json`.
- **No Masked Keys**: To prevent leakage in screenshots or screen shares, the dashboard **never** displays your API key or any part of it (no masked fragments like `sk-****1234`).
- **Input Security**: New keys are entered via a `password` type input in the Settings panel.
- **Zero Telemetry**: No data leaves your machine except for direct calls to the official DeepSeek API.
- **GitHub Safety**: If you accidentally commit a file containing an API key, **revoke/regenerate** your DeepSeek API key immediately at the [DeepSeek Platform](https://platform.deepseek.com/).
- **Shared Versions**: The default version on GitHub contains no API keys or configuration traces.

---

## Architecture

| Component | Technology | URL |
|-----------|------------|-----|
| Frontend | React + TypeScript + Vite | http://localhost:5173 |
| Backend | Python + FastAPI | http://127.0.0.1:8789 |
| Balance API | DeepSeek `/user/balance` | external |

---

## Project Structure

```
deepseek UI/
├── dashboard.html          ← Launcher/help page (static)
├── start-mac.command       ← macOS double-click launcher
├── start-windows.bat       ← Windows double-click launcher
├── src/                    ← React frontend source
│   ├── components/
│   │   ├── CircularGauge.tsx
│   │   ├── ModelUsage.tsx
│   │   ├── MetricCard.tsx
│   │   ├── RecentRequests.tsx
│   │   ├── RefreshControl.tsx
│   │   ├── MiniTrendCard.tsx
│   │   └── SettingsPanel.tsx
│   ├── App.tsx
│   ├── api.ts
│   ├── mockData.ts
│   └── index.css
├── backend/
│   ├── main.py             ← FastAPI app
│   ├── config.py           ← Environment config
│   ├── deepseek_client.py  ← Balance API client
│   ├── requirements.txt
│   ├── .env.example        ← Template (safe to commit)
│   ├── .env                ← Your secrets (gitignored)
│   └── local_settings.json ← Settings panel data (gitignored)
└── package.json
```

---

## Features

- **Real-time balance** from DeepSeek `/user/balance`
- **Total Spend estimation** via configurable initial credit
- **Dot-matrix LED balance display** — custom SVG-rendered 5×7 pixel font
- **Segmented progress arc** with precision balance marker
- **Model usage breakdown** (today's requests, tokens, cost)
- **Recent requests log** with latency and status
- **Mini trend sparklines** (spend, tokens, requests)
- **Settings panel** — configure API key and credit without editing files
- **Light / Dark mode** — Nothing-inspired industrial aesthetic
- **Focus mode** — hide right panel for gauge-only view
- **1600×900 stage** with proportional scaling

---

## Roadmap

- [ ] Support for monthly usage breakdown (requires OpenAI-compatible proxy or SQLite logging)
- [ ] Add more granular cost visualizations
- [ ] Multi-account support

---

## Disclaimer

This is a third-party, open-source tool and is not officially affiliated with or endorsed by DeepSeek. Use it at your own risk.

---

## License

TBD (To Be Determined)
