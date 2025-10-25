"""
HTTP endpoint handlers for Firebase Cloud Functions.
"""
import logging
import json
from firebase_functions import https_fn, options
from firebase_admin import firestore, messaging
from utils.ai_utils import generate_ai_response, extract_json_from_response
from utils.web_utils import search_duckduckgo, scrape_webpage
from utils.image_utils import generate_dalle_image, create_animated_gif, cleanup_temp_file
from utils.notification_utils import send_message_notification
from config import Config
from prompts import TRANSLATION_SYSTEM_PROMPT, get_translation_user_prompt

logger = logging.getLogger(__name__)

@https_fn.on_request()
def test_notification(req: https_fn.Request) -> https_fn.Response:
    """
    Test endpoint for sending push notifications.
    
    Usage:
    POST /test_notification
    {
        "userId": "user_abc123",
        "title": "Test",
        "body": "Test notification"
    }
    """
    try:
        data = req.get_json()
        user_id = data.get("userId")
        title = data.get("title", "Test")
        body = data.get("body", "Test notification")
        
        if not user_id:
            return https_fn.Response("Missing userId", status=400)
        
        db = firestore.client()
        
        # Get user's FCM token
        user_ref = db.collection("users").document(user_id)
        user = user_ref.get()
        
        if not user.exists:
            return https_fn.Response("User not found", status=404)
        
        user_data = user.to_dict()
        fcm_token = user_data.get("fcmToken")
        
        if not fcm_token:
            return https_fn.Response("No FCM token for user", status=404)
        
        # Send notification
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body
            ),
            token=fcm_token
        )
        
        response = messaging.send(message)
        
        return https_fn.Response(f"Notification sent: {response}", status=200)
        
    except Exception as e:
        logger.error(f"Error in test_notification: {e}", exc_info=True)
        return https_fn.Response(f"Error: {str(e)}", status=500)


@https_fn.on_request()
def health_check(req: https_fn.Request) -> https_fn.Response:
    """
    Health check endpoint.
    """
    return https_fn.Response("OK", status=200)


@https_fn.on_request(cors=options.CorsOptions(
    cors_origins=Config.CORS_ORIGINS,
    cors_methods=Config.CORS_METHODS
))
def translate_text(req: https_fn.Request) -> https_fn.Response:
    """
    Translate text to a target language using OpenAI.

    Request Body:
    {
        "text": "Hello, how are you?",
        "target_language": "es",          # ISO 639-1 code (e.g., en, es, fr)
        "source_language": "en"           # optional, ISO 639-1
    }

    Response:
    {
        "translated_text": "Hola, ¿cómo estás?",
        "detected_language": "en"
    }
    """
    try:
        # Handle CORS preflight
        if req.method == "OPTIONS":
            return https_fn.Response(
                status=204,
                headers={
                    "Access-Control-Allow-Origin": Config.CORS_ORIGINS,
                    "Access-Control-Allow-Methods": ", ".join(Config.CORS_METHODS),
                    "Access-Control-Allow-Headers": Config.CORS_HEADERS,
                    "Access-Control-Max-Age": Config.CORS_MAX_AGE
                }
            )

        data = req.get_json()
        if not data:
            return https_fn.Response(
                json.dumps({"error": "Missing request body"}),
                status=400,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
            )

        # Handle text fields - ensure they're strings
        text_raw = data.get("text")
        text = str(text_raw).strip() if text_raw and not isinstance(text_raw, list) else ""
        if isinstance(text_raw, list):
            text = " ".join(str(item) for item in text_raw if item)
        
        target_language_raw = data.get("target_language")
        target_language = str(target_language_raw).strip() if target_language_raw and not isinstance(target_language_raw, list) else ""
        
        source_language_raw = data.get("source_language")
        source_language = str(source_language_raw).strip() if source_language_raw and not isinstance(source_language_raw, list) else ""

        if not text or not target_language:
            return https_fn.Response(
                json.dumps({"error": "Both 'text' and 'target_language' are required"}),
                status=400,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
            )

        if not Config.OPENAI_API_KEY:
            logger.error("OPENAI_API_KEY not set in environment")
            return https_fn.Response(
                json.dumps({"error": "OpenAI API key not configured"}),
                status=500,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
            )

        system_prompt = TRANSLATION_SYSTEM_PROMPT
        user_prompt = get_translation_user_prompt(target_language, text, source_language)

        response_text = generate_ai_response(system_prompt, user_prompt, temperature=0.2)

        # Extract JSON if wrapped in code fences
        if "```json" in response_text:
            start = response_text.find("```json") + 7
            end = response_text.find("```", start)
            response_text = response_text[start:end].strip()
        elif "```" in response_text:
            start = response_text.find("```") + 3
            end = response_text.find("```", start)
            response_text = response_text[start:end].strip()

        try:
            data_out = json.loads(response_text)
            translated_text = data_out.get("translated_text")
            detected_language = data_out.get("detected_language") or source_language or ""
            if not translated_text:
                raise ValueError("Missing translated_text")
        except Exception as e:
            # Fallback: treat entire response as translation
            logger.warning(f"Failed to parse JSON; returning raw text. Error: {e}")
            translated_text = response_text.strip()
            detected_language = source_language or ""

        return https_fn.Response(
            json.dumps({
                "translated_text": translated_text,
                "detected_language": detected_language
            }),
            status=200,
            headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
        )

    except Exception as e:
        logger.error(f"Error in translate_text: {e}", exc_info=True)
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
        )
