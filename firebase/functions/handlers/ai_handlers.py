"""
AI-powered endpoint handlers for Firebase Cloud Functions.
"""
import logging
import json
from firebase_functions import https_fn, options
from firebase_admin import firestore
from utils.ai_utils import generate_ai_response, extract_json_from_response
from utils.web_utils import search_duckduckgo, scrape_webpage
from utils.image_utils import generate_dalle_image, create_animated_gif, cleanup_temp_file
from config import Config
from prompts import (
    CULTURAL_ANALYSIS_SYSTEM_PROMPT, get_cultural_analysis_user_prompt,
    get_language_tutor_system_prompt, get_language_tutor_user_prompt, get_translation_prompt,
    get_language_name
)

logger = logging.getLogger(__name__)

@https_fn.on_request(cors=options.CorsOptions(
    cors_origins=Config.CORS_ORIGINS,
    cors_methods=Config.CORS_METHODS
))
def message_context(req: https_fn.Request) -> https_fn.Response:
    """
    Provide cultural/contextual insights about a selected message in relation to
    its surrounding conversation messages.

    Request Body:
    {
        "selected_message": "I'll circle back later 👍",
        "conversation_history": [  # optional but recommended; last ~10 is enough
            {"sender_id": "1", "sender_name": "Alice", "content": "...", "timestamp": "...", "is_from_current_user": false},
            ...
        ]
    }

    Response:
    { "context": "Short analysis with cultural notes, tone, idioms, and potential misreadings." }
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

        # Parse request body
        data = req.get_json()
        
        if not data:
            return https_fn.Response(
                json.dumps({"error": "Missing request body"}),
                status=400,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
            )
        
        selected_message = data.get("selected_message", "").strip()
        conversation_history = data.get("conversation_history", [])
        
        if not selected_message:
            return https_fn.Response(
                json.dumps({"error": "'selected_message' is required and cannot be empty"}),
                status=400,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
            )
        
        logger.info(f"🌍 Generating cultural context for: {selected_message[:50]}...")
        
        if not Config.OPENAI_API_KEY:
            logger.error("OPENAI_API_KEY not set in environment")
            return https_fn.Response(
                json.dumps({"error": "OpenAI API key not configured"}),
                status=500,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
            )
        
        # Format conversation history if provided
        conversation_context = ""
        if conversation_history:
            conversation_text = "\n".join([
                f"{msg.get('sender_name', 'Unknown')}: {msg.get('content', '')}"
                for msg in conversation_history[-10:]  # Last 10 messages
            ])
            conversation_context = f"\n\nConversation context (recent messages):\n{conversation_text}\n"
        
        # Create comprehensive cultural analysis prompt
        system_prompt = CULTURAL_ANALYSIS_SYSTEM_PROMPT
        user_prompt = get_cultural_analysis_user_prompt(selected_message, conversation_context)
        
        context_analysis = generate_ai_response(system_prompt, user_prompt, temperature=0.7)
        
        logger.info(f"✅ Cultural context generated ({len(context_analysis)} chars)")
        
        return https_fn.Response(
            json.dumps({
                "context": context_analysis
            }),
            status=200,
            headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
        )

    except Exception as e:
        logger.error(f"Error in message_context: {e}", exc_info=True)
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
        )


@https_fn.on_request(cors=options.CorsOptions(
    cors_origins=Config.CORS_ORIGINS,
    cors_methods=Config.CORS_METHODS
))
def language_tutor(req: https_fn.Request) -> https_fn.Response:
    """
    AI-powered language tutor that helps users learn a new language through conversation.
    
    Request Body:
    {
        "user_message": "Hola, ¿cómo estás?",
        "conversation_history": [
            {"role": "user", "content": "..."},
            {"role": "assistant", "content": "..."}
        ],
        "learning_language": "es",  // ISO language code
        "primary_language": "en"     // ISO language code
    }
    
    Response:
    {
        "message": "¡Muy bien, gracias! ¿Y tú? How are you doing with your Spanish practice today?",
        "translation": "Very good, thanks! And you? How are you doing with your Spanish practice today?"
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
        
        # Parse request body
        data = req.get_json()
        
        if not data:
            return https_fn.Response(
                json.dumps({"error": "Missing request body"}),
                status=400,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
            )
        
        user_message = data.get("user_message", "").strip()
        conversation_history = data.get("conversation_history", [])
        learning_language = data.get("learning_language", "es")
        primary_language = data.get("primary_language", "en")
        
        if not user_message:
            return https_fn.Response(
                json.dumps({"error": "'user_message' is required and cannot be empty"}),
                status=400,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
            )
        
        logger.info(f"🎓 Language tutor: {learning_language} message from user")
        
        if not Config.OPENAI_API_KEY:
            logger.error("OPENAI_API_KEY not set in environment")
            return https_fn.Response(
                json.dumps({"error": "OpenAI API key not configured"}),
                status=500,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
            )
        
        # Get language names
        learning_lang_name = get_language_name(learning_language)
        primary_lang_name = get_language_name(primary_language)
        
        # Create tutor system prompt
        system_prompt = get_language_tutor_system_prompt(learning_lang_name, primary_lang_name)

        # Format conversation history
        formatted_history = []
        for msg in conversation_history[-10:]:  # Last 10 messages
            role = msg.get("role", "user")
            content = msg.get("content", "")
            if role == "user":
                formatted_history.append(f"Student: {content}")
            elif role == "assistant":
                formatted_history.append(f"Tutor: {content}")
        
        conversation_context = "\n".join(formatted_history)
        
        user_prompt = get_language_tutor_user_prompt(conversation_context, user_message)
        
        tutor_message = generate_ai_response(system_prompt, user_prompt, temperature=0.8)
        
        # Generate translation of the tutor's response
        translation_prompt = get_translation_prompt(learning_lang_name, primary_lang_name, tutor_message)

        translation = generate_ai_response(translation_prompt, "", temperature=0.2)
        
        logger.info(f"✅ Language tutor response generated ({len(tutor_message)} chars)")
        
        return https_fn.Response(
            json.dumps({
                "message": tutor_message,
                "translation": translation
            }),
            status=200,
            headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
        )
    
    except Exception as e:
        logger.error(f"Error in language_tutor: {e}", exc_info=True)
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
        )
