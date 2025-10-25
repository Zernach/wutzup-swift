"""
Cloud Functions for Wutzup Messaging App

This module contains Firebase Cloud Functions for handling:
- Push notifications when messages are created
- User presence tracking
- Conversation updates
- AI-powered response suggestions
- Language tutoring
- Web research
- GIF generation
"""

from firebase_admin import initialize_app
from firebase_functions import options
import logging

# Initialize Firebase Admin SDK
app = initialize_app()

# Configure global options
from config import Config
Config.validate()  # Validate configuration on startup
options.set_global_options(max_instances=Config.MAX_INSTANCES)

# Setup logging
logger = logging.getLogger(__name__)

# Import all handlers to register functions
from handlers.message_handlers import on_message_created
from handlers.conversation_handlers import on_conversation_created, on_presence_updated
from handlers.http_handlers import test_notification, health_check, translate_text
from handlers.ai_handlers import message_context, language_tutor
from handlers.response_handlers import generate_response_suggestions
from handlers.gif_handlers import generate_gif
from handlers.research_handlers import conduct_research
from handlers.tutor_handlers import generate_tutor_greeting, generate_tutor_response

logger.info("Firebase Cloud Functions initialized successfully")
logger.info(f"Configuration: MAX_INSTANCES={Config.MAX_INSTANCES}, CORS_ORIGINS={Config.CORS_ORIGINS}")