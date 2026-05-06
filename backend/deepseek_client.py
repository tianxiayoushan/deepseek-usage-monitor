import httpx

DEEPSEEK_API_URL = "https://api.deepseek.com/user/balance"

async def fetch_balance(api_key: str):
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Accept": "application/json"
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.get(DEEPSEEK_API_URL, headers=headers, timeout=10.0)
        response.raise_for_status()
        return response.json()
