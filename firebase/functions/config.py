"""
Configuration management for Firebase Cloud Functions.
"""
import os
from typing import Optional
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class Config:
    """Application configuration."""
    
    # Firebase configuration
    FIREBASE_PROJECT_ID: str = os.getenv("FIREBASE_PROJECT_ID", "")
    
    # OpenAI configuration
    OPENAI_API_KEY: Optional[str] = os.getenv("OPENAI_API_KEY")
    
    # Function configuration
    MAX_INSTANCES: int = int(os.getenv("MAX_INSTANCES", "10"))
    
    # CORS configuration
    CORS_ORIGINS: str = os.getenv("CORS_ORIGINS", "*")
    CORS_METHODS: list = ["POST", "OPTIONS"]
    CORS_HEADERS: str = "Content-Type"
    CORS_MAX_AGE: str = "3600"
    
    # AI Model configuration
    DEFAULT_AI_MODEL: str = "gpt-4o-mini"
    AI_TEMPERATURE: float = float(os.getenv("AI_TEMPERATURE", "0.7"))
    
    # Image generation configuration
    DALL_E_MODEL: str = "dall-e-3"
    IMAGE_SIZE: str = "1024x1024"
    GIF_FRAME_SIZE: tuple = (512, 512)
    GIF_DURATION: int = 500  # milliseconds
    
    # Web scraping configuration
    REQUEST_TIMEOUT: int = int(os.getenv("REQUEST_TIMEOUT", "10"))
    MAX_SEARCH_RESULTS: int = int(os.getenv("MAX_SEARCH_RESULTS", "5"))
    MAX_SCRAPED_CONTENT_LENGTH: int = int(os.getenv("MAX_SCRAPED_CONTENT_LENGTH", "1000"))
    
    # Notification configuration
    NOTIFICATION_PREVIEW_LENGTH: int = 100
    
    @classmethod
    def validate(cls) -> bool:
        """Validate that required configuration is present."""
        if not cls.OPENAI_API_KEY:
            raise ValueError("OPENAI_API_KEY is required")
        return True
