#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# start-mac.command — DeepSeek Usage Monitor
# Double-click this file in Finder to start the app.
#
# First-time setup:
#   chmod +x start-mac.command
#
# This script will:
#   1. Check for Node.js and Python 3.10+
#   2. Install frontend npm dependencies if needed
#   3. Create a Python venv and install backend dependencies if needed
#   4. Start the FastAPI backend (background)
#   5. Start the Vite frontend (foreground)
#   6. Open http://localhost:5173 in your browser
#   7. Clean up both processes on exit (Ctrl+C or window close)
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Resolve project root (handles paths with spaces) ────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ── Color helpers ────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()  { echo -e "${CYAN}[INFO]${RESET}  $*"; }
ok()    { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error() { echo -e "${RED}[ERROR]${RESET} $*"; }

echo ""
echo -e "${BOLD}  DeepSeek Usage Monitor — Launcher${RESET}"
echo -e "  ${CYAN}v0.2.2 · macOS${RESET}"
echo "  ─────────────────────────────────────"
echo ""

# ── Track background PIDs for clean shutdown ─────────────────────────
BACKEND_PID=""
FRONTEND_PID=""

cleanup() {
  echo ""
  echo -e "${YELLOW}Stopping DeepSeek Usage Monitor...${RESET}"
  # Kill children of background processes too (venv uvicorn, node, etc.)
  if [[ -n "$BACKEND_PID" ]]; then
    kill "$BACKEND_PID" 2>/dev/null || true
    # Kill any child processes
    pkill -P "$BACKEND_PID" 2>/dev/null || true
  fi
  if [[ -n "$FRONTEND_PID" ]]; then
    kill "$FRONTEND_PID" 2>/dev/null || true
    pkill -P "$FRONTEND_PID" 2>/dev/null || true
  fi
  # Fallback: kill by port in case PIDs have already died
  lsof -ti :8789 | xargs kill -9 2>/dev/null || true
  lsof -ti :5173 | xargs kill -9 2>/dev/null || true
  echo -e "${GREEN}DeepSeek Usage Monitor stopped.${RESET}"
  exit 0
}

# Register cleanup for all exit scenarios
trap cleanup EXIT INT TERM

# ── 1. Check Node.js ─────────────────────────────────────────────────
info "Checking Node.js..."
if ! command -v node &>/dev/null; then
  error "Node.js is not installed or not in PATH."
  echo "  Please install Node.js 18+ from: https://nodejs.org/"
  echo "  Then run this script again."
  read -r -p "Press Enter to exit..."
  exit 1
fi
NODE_VERSION=$(node --version)
ok "Node.js found: $NODE_VERSION"

# ── 2. Check npm ─────────────────────────────────────────────────────
if ! command -v npm &>/dev/null; then
  error "npm is not installed or not in PATH."
  echo "  npm usually comes with Node.js. Reinstall Node.js from: https://nodejs.org/"
  read -r -p "Press Enter to exit..."
  exit 1
fi
ok "npm found: $(npm --version)"

# ── Python version helpers ────────────────────────────────────────────
python_version_ok() {
  "$1" - <<'PY'
import sys

sys.exit(0 if sys.version_info >= (3, 10) else 1)
PY
}

python_version_text() {
  "$1" --version 2>&1
}

# ── 3. Check Python 3.10+ ────────────────────────────────────────────
info "Checking Python 3.10+..."
PYTHON_CMD=""
for candidate in python3.11 python3.10 python3 python; do
  if command -v "$candidate" &>/dev/null; then
    PYTHON_CMD="$candidate"
    break
  fi
done

if [[ -z "$PYTHON_CMD" ]]; then
  error "Python is not installed or not in PATH."
  echo "  Python >= 3.10 is required. Please install Python 3.10+ or make python3.10 available in PATH."
  read -r -p "Press Enter to exit..."
  exit 1
fi

PYTHON_VERSION=$(python_version_text "$PYTHON_CMD")
if ! python_version_ok "$PYTHON_CMD"; then
  error "$PYTHON_VERSION found, but Python >= 3.10 is required."
  echo "  Python >= 3.10 is required. Please install Python 3.10+ or make python3.10 available in PATH."
  read -r -p "Press Enter to exit..."
  exit 1
fi
ok "Python found: $PYTHON_VERSION"

# ── 4. Frontend npm install ───────────────────────────────────────────
if [[ ! -d "$SCRIPT_DIR/node_modules" ]]; then
  warn "node_modules not found. Running npm install (first time, may take a minute)..."
  npm install || { error "npm install failed."; read -r -p "Press Enter to exit..."; exit 1; }
  ok "Frontend dependencies installed."
else
  ok "node_modules found, skipping npm install."
fi

# ── 5. Backend setup ──────────────────────────────────────────────────
BACKEND_DIR="$SCRIPT_DIR/backend"
cd "$BACKEND_DIR"

if [[ ! -d ".venv" ]]; then
  info "Creating Python virtual environment..."
  "$PYTHON_CMD" -m venv .venv || { error "Failed to create virtual environment."; exit 1; }
  ok "Virtual environment created."
elif [[ -x ".venv/bin/python" ]]; then
  VENV_PYTHON_VERSION=$(python_version_text ".venv/bin/python")
  if ! python_version_ok ".venv/bin/python"; then
    error "Existing backend/.venv uses $VENV_PYTHON_VERSION, but Python >= 3.10 is required."
    echo "  Delete backend/.venv and run this script again, or rebuild it with Python 3.10+."
    read -r -p "Press Enter to exit..."
    exit 1
  fi
  ok "Existing backend virtual environment uses $VENV_PYTHON_VERSION."
else
  error "Existing backend/.venv is missing bin/python."
  echo "  Delete backend/.venv and run this script again."
  read -r -p "Press Enter to exit..."
  exit 1
fi

info "Activating virtual environment..."
# shellcheck source=/dev/null
source ".venv/bin/activate"
ok "Virtual environment activated."

info "Installing backend dependencies..."
pip install -q -r requirements.txt || { error "pip install failed. Check requirements.txt."; exit 1; }
ok "Backend dependencies installed."

# ── 6. .env setup ────────────────────────────────────────────────────
if [[ ! -f ".env" ]]; then
  if [[ -f ".env.example" ]]; then
    cp ".env.example" ".env"
    warn ".env not found — copied from .env.example."
    warn "Open Settings in the Dashboard to enter your DeepSeek API Key."
  else
    warn ".env.example not found either. The backend will start without an API key."
    warn "Use the Dashboard Settings panel to enter your API key after launch."
  fi
else
  ok ".env file found."
fi

# ── 7. Start backend ──────────────────────────────────────────────────
cd "$BACKEND_DIR"
echo ""
info "Starting FastAPI backend on http://127.0.0.1:8789 ..."
uvicorn main:app --host 127.0.0.1 --port 8789 --reload &
BACKEND_PID=$!
ok "Backend started (PID: $BACKEND_PID)"

# ── 8. Wait for backend to be ready ──────────────────────────────────
info "Waiting for backend to become ready..."
MAX_WAIT=20
ELAPSED=0
while ! curl -sf "http://127.0.0.1:8789/api/health" >/dev/null 2>&1; do
  sleep 1
  ELAPSED=$((ELAPSED + 1))
  if [[ $ELAPSED -ge $MAX_WAIT ]]; then
    warn "Backend did not respond within ${MAX_WAIT}s. Continuing anyway..."
    break
  fi
done
if curl -sf "http://127.0.0.1:8789/api/health" >/dev/null 2>&1; then
  ok "Backend is healthy."
fi

# ── 9. Start frontend ─────────────────────────────────────────────────
cd "$SCRIPT_DIR"
echo ""
info "Starting Vite frontend on http://localhost:5173 ..."
npm run dev -- --host 127.0.0.1 &
FRONTEND_PID=$!
ok "Frontend started (PID: $FRONTEND_PID)"

# ── 10. Wait and open browser ─────────────────────────────────────────
info "Waiting 4s for Vite to compile, then opening browser..."
sleep 4
open "http://localhost:5173" 2>/dev/null || true

echo ""
echo "  ─────────────────────────────────────────────────────────────"
echo -e "  ${GREEN}${BOLD}DeepSeek Usage Monitor is running!${RESET}"
echo ""
echo -e "  ${CYAN}Dashboard:${RESET} http://localhost:5173"
echo -e "  ${CYAN}Backend:${RESET}   http://127.0.0.1:8789/api/health"
echo ""
echo -e "  ${YELLOW}Press Ctrl+C to stop all services.${RESET}"
echo "  ─────────────────────────────────────────────────────────────"
echo ""

# ── 11. Wait for user to stop ─────────────────────────────────────────
# Keep this script alive so trap fires on Ctrl+C
# Also watch for background processes dying unexpectedly
while true; do
  # If backend died, report it
  if ! kill -0 "$BACKEND_PID" 2>/dev/null; then
    warn "Backend process has stopped unexpectedly."
    BACKEND_PID=""
    break
  fi
  # If frontend died, report it
  if ! kill -0 "$FRONTEND_PID" 2>/dev/null; then
    warn "Frontend process has stopped unexpectedly."
    FRONTEND_PID=""
    break
  fi
  sleep 2
done

echo ""
warn "One or more processes stopped. Shutting down..."
# cleanup is called by EXIT trap
