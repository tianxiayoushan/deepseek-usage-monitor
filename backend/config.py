import os
from dotenv import load_dotenv

load_dotenv()

DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY")

def _parse_float_or_none(val: str | None) -> float | None:
    if val is None:
        return None
    try:
        return float(val)
    except (ValueError, TypeError):
        return None

# Read INITIAL_TOTAL_CREDIT_CNY from .env as the env-level default.
# local_settings.json takes priority over this value (handled in main.py).
INITIAL_TOTAL_CREDIT_CNY_ENV: float | None = _parse_float_or_none(
    os.getenv("INITIAL_TOTAL_CREDIT_CNY")
)
