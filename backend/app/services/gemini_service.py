import logging
from typing import Optional
from app.core.config import settings

logger = logging.getLogger("aegispatrol.gemini")

class GeminiService:
    """
    Placeholder service for Gemini API integration.
    This prepares the client and configuration so future teammates can add AI features
    (e.g., safety journey analysis, automated risk insights) without modifying the core architecture.
    """
    def __init__(self):
        self.api_key: str = settings.GEMINI_API_KEY
        self.is_configured: bool = bool(self.api_key and self.api_key != "PASTE_YOUR_GEMINI_API_KEY_HERE")
        if self.is_configured:
            try:
                import google.generativeai as genai
                genai.configure(api_key=self.api_key)
                try:
                    self.model = genai.GenerativeModel("gemini-2.5-flash")
                except Exception:
                    self.model = genai.GenerativeModel("gemini-1.5-flash")
                logger.info("Gemini AI service configured successfully.")
            except Exception as e:
                logger.warning("Could not initialize google.generativeai: %s", e)
                self.model = None
        else:
            self.model = None
            logger.info("Gemini API key is not configured yet. AI features will remain dormant.")

    async def generate_response(self, prompt: str) -> Optional[str]:
        """
        Placeholder method for generating text responses from Gemini.
        NOTE: This is not called during auth or initial navigation.
        """
        if not self.is_configured or not self.model:
            logger.warning("Gemini AI is not configured. Returning placeholder response.")
            return "Gemini AI is not yet configured with a valid API key."
        try:
            response = self.model.generate_content(prompt)
            return response.text
        except Exception as e:
            logger.error("Error generating Gemini AI response: %s", e)
            return None

gemini_service = GeminiService()
