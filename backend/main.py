import os
import json
from pathlib import Path
from datetime import datetime, timezone
from typing import Optional

from fastapi import FastAPI, Body
from fastapi.middleware.cors import CORSMiddleware
import httpx

from config import DEEPSEEK_API_KEY, INITIAL_TOTAL_CREDIT_CNY_ENV
from deepseek_client import fetch_balance

app = FastAPI(title="DeepSeek Usage Monitor Backend")

# CORS middleware – accept any localhost / 127.0.0.1 port (Vite dev varies)
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^http://(localhost|127\.0\.0\.1):\d+$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── local_settings.json ──────────────────────────────────────────────────────
# Priority: local_settings.json > .env INITIAL_TOTAL_CREDIT_CNY > None
_SETTINGS_FILE = Path(__file__).parent / "local_settings.json"


def _load_local_settings() -> dict:
    if _SETTINGS_FILE.exists():
        try:
            return json.loads(_SETTINGS_FILE.read_text())
        except Exception:
            pass
    return {}


def _save_local_settings(settings: dict) -> None:
    _SETTINGS_FILE.write_text(json.dumps(settings, indent=2))


def _get_active_api_key() -> Optional[str]:
    """Return api_key with local_settings priority over .env."""
    local = _load_local_settings()
    if local.get("deepseek_api_key"):
        return local["deepseek_api_key"]
    return DEEPSEEK_API_KEY


def _get_initial_total_credit() -> Optional[float]:
    """Return initial_total_credit with local_settings priority over .env."""
    local = _load_local_settings()
    if "initial_total_credit" in local and local["initial_total_credit"] is not None:
        try:
            return float(local["initial_total_credit"])
        except (ValueError, TypeError):
            pass
    return INITIAL_TOTAL_CREDIT_CNY_ENV


# ── /api/health ──────────────────────────────────────────────────────────────

@app.get("/api/health")
async def health_check():
    return {
        "status": "ok",
        "service": "deepseek-usage-monitor-backend"
    }


# ── /api/settings ─────────────────────────────────────────────────────────────

@app.get("/api/settings")
async def get_settings():
    now_iso = datetime.now(timezone.utc).isoformat()
    active_key = _get_active_api_key()
    api_key_configured = bool(active_key)

    initial_credit = _get_initial_total_credit()
    return {
        "api_key_configured": api_key_configured,
        "initial_total_credit": initial_credit,
        "initial_total_credit_configured": initial_credit is not None,
        "updated_at": now_iso,
    }


@app.post("/api/settings")
async def save_settings(payload: dict = Body(...)):
    """Save initial_total_credit and api_key to local_settings.json."""
    local = _load_local_settings()

    if "initial_total_credit" in payload:
        try:
            if payload["initial_total_credit"] is None:
                local["initial_total_credit"] = None
            else:
                local["initial_total_credit"] = float(payload["initial_total_credit"])
        except (ValueError, TypeError):
            pass

    if "deepseek_api_key" in payload and payload["deepseek_api_key"]:
        local["deepseek_api_key"] = payload["deepseek_api_key"]

    _save_local_settings(local)
    return {"ok": True}


# ── /api/balance ──────────────────────────────────────────────────────────────

@app.get("/api/balance")
async def get_balance():
    now_iso = datetime.now(timezone.utc).isoformat()
    active_key = _get_active_api_key()

    if not active_key:
        return {
            "available": False,
            "error": "DEEPSEEK_API_KEY is not configured",
            "currency": "CNY",
            "total_balance": None,
            "historical_total_spend": None,
            "historical_total_spend_available": False,
            "updated_at": now_iso,
        }

    try:
        data = await fetch_balance(active_key)

        # Find CNY balance_info
        balance_infos = data.get("balance_infos", [])
        cny_info = next(
            (info for info in balance_infos if info.get("currency") == "CNY"), None
        )

        if not cny_info:
            return {
                "available": False,
                "error": "CNY balance not found in DeepSeek response",
                "currency": "CNY",
                "total_balance": None,
                "historical_total_spend": None,
                "historical_total_spend_available": False,
                "updated_at": now_iso,
                "raw": data,
            }

        total_balance = float(cny_info.get("total_balance", 0))
        granted_balance = float(cny_info.get("granted_balance", 0))
        topped_up_balance = float(cny_info.get("topped_up_balance", 0))

        # Compute historical spend
        initial_credit = _get_initial_total_credit()
        if initial_credit is not None:
            historical_spend = max(initial_credit - total_balance, 0.0)
            historical_spend_available = True
        else:
            historical_spend = None
            historical_spend_available = False

        return {
            "available": data.get("is_available", True),
            "currency": "CNY",
            "total_balance": total_balance,
            "granted_balance": granted_balance,
            "topped_up_balance": topped_up_balance,
            "initial_total_credit": initial_credit,
            "historical_total_spend": historical_spend,
            "historical_total_spend_available": historical_spend_available,
            "raw": data,
            "updated_at": now_iso,
        }

    except httpx.HTTPStatusError as e:
        return {
            "available": False,
            "error": f"HTTP Error {e.response.status_code}",
            "currency": "CNY",
            "total_balance": None,
            "historical_total_spend": None,
            "historical_total_spend_available": False,
            "updated_at": now_iso,
        }
    except Exception as e:
        return {
            "available": False,
            "error": str(e),
            "currency": "CNY",
            "total_balance": None,
            "historical_total_spend": None,
            "historical_total_spend_available": False,
            "updated_at": now_iso,
        }
