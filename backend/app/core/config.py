import os
from pydantic_settings import BaseSettings
from pydantic import ConfigDict
from dotenv import load_dotenv

load_dotenv()

class Settings(BaseSettings):
    PROJECT_NAME: str = "AegisPatrol API"
    API_V1_STR: str = "/api/v1"
    
    # MongoDB
    MONGO_URI: str = os.getenv("MONGO_URI", "mongodb://localhost:27017")
    DATABASE_NAME: str = os.getenv("DATABASE_NAME", "dhaal")
    
    # JWT
    JWT_SECRET: str = os.getenv("JWT_SECRET", "aegispatrol_super_secret_jwt_key_2026_change_in_production")
    JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))
    
    # Gemini AI Placeholder
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")

    # Render Self-Pinging Keep-Alive Configuration
    RENDER_EXTERNAL_URL: str = os.getenv("RENDER_EXTERNAL_URL", "")
    BACKEND_URL: str = os.getenv("BACKEND_URL", "")
    SELF_PING_ENABLED: bool = os.getenv("SELF_PING_ENABLED", "true").lower() in ("true", "1", "yes")
    SELF_PING_INTERVAL_SECONDS: int = int(os.getenv("SELF_PING_INTERVAL_SECONDS", "600"))

    model_config = ConfigDict(
        env_file=".env",
        extra="ignore"
    )

settings = Settings()
