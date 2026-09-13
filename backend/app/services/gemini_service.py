import logging
from typing import Optional
import httpx
from app.core.config import settings

logger = logging.getLogger("aegispatrol.gemini")

class GeminiService:
    """
    Lightweight, dependency-free Gemini API integration service.
    Uses async HTTP REST endpoints directly with zero deprecation warnings.
    """
    def __init__(self):
        self.api_key: str = (settings.GEMINI_API_KEY or "").strip()
        self.is_configured: bool = bool(
            self.api_key
            and self.api_key != "PASTE_YOUR_GEMINI_API_KEY_HERE"
            and len(self.api_key) > 10
        )
        self.endpoint = (
            f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={self.api_key}"
            if self.is_configured
            else ""
        )

    async def generate_response(self, prompt: str) -> Optional[str]:
        """
        Generates text responses from Gemini 1.5 Flash via REST API.
        """
        if not self.is_configured:
            return "Gemini AI is not configured with a valid API key."

        try:
            payload = {
                "contents": [
                    {
                        "parts": [{"text": prompt}]
                    }
                ]
            }
            async with httpx.AsyncClient(timeout=15.0) as client:
                res = await client.post(self.endpoint, json=payload)
                if res.status_code == 200:
                    data = res.json()
                    candidates = data.get("candidates", [])
                    if candidates:
                        parts = candidates[0].get("content", {}).get("parts", [])
                        if parts:
                            return parts[0].get("text", "")
                    return ""
                else:
                    logger.warning("Gemini REST API error %s: %s", res.status_code, res.text)
                    return None
        except Exception as e:
            logger.error("Error communicating with Gemini API: %s", e)
            return None

gemini_service = GeminiService()
