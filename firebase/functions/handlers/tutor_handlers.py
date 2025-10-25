"""
Tutor AI chat handlers for Firebase Cloud Functions.
"""
import logging
import json
from firebase_functions import https_fn, options
from firebase_admin import firestore
from utils.ai_utils import generate_ai_response
from config import Config
from prompts import (
    get_tutor_greeting_system_prompt, get_tutor_greeting_user_prompt,
    get_tutor_response_system_prompt, get_tutor_response_user_prompt
)

logger = logging.getLogger(__name__)

@https_fn.on_request(cors=options.CorsOptions(
    cors_origins=Config.CORS_ORIGINS,
    cors_methods=Config.CORS_METHODS
))
def generate_tutor_greeting(req: https_fn.Request) -> https_fn.Response:
    """
    Generate an initial AI greeting from a tutor based on their personality.
    
    This endpoint is called automatically when a conversation with a tutor is created.
    The tutor will send a welcoming message that matches their personality and ends
    with a question to engage the user.
    
    Request Body:
    {
        "tutor_id": "tutor_abc123",
        "tutor_personality": "A friendly Spanish teacher from Barcelona...",
        "tutor_name": "Sofia Martinez",
        "user_name": "John",
        "conversation_id": "conv_xyz789"
    }
    
    Response:
    {
        "greeting": "¡Hola! I'm Sofia, your Spanish tutor...",
        "message_id": "msg_abc123"
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
        
        tutor_id = data.get("tutor_id", "").strip()
        tutor_personality = data.get("tutor_personality", "").strip()
        tutor_name = data.get("tutor_name", "").strip()
        user_name = data.get("user_name", "Unknown")
        conversation_id = data.get("conversation_id", "").strip()
        group_name = data.get("group_name", "").strip()  # Optional group name
        
        if not tutor_id or not tutor_personality or not tutor_name or not conversation_id:
            return https_fn.Response(
                json.dumps({"error": "tutor_id, tutor_personality, tutor_name, and conversation_id are required"}),
                status=400,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
            )
        
        logger.info(f"🎓 Generating greeting from tutor {tutor_name} for conversation {conversation_id}" + 
                   (f" (group: {group_name})" if group_name else ""))
        
        if not Config.OPENAI_API_KEY:
            logger.error("OPENAI_API_KEY not set in environment")
            return https_fn.Response(
                json.dumps({"error": "OpenAI API key not configured"}),
                status=500,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
            )
        
        # Create greeting prompt with optional group context
        system_prompt = get_tutor_greeting_system_prompt(tutor_name, tutor_personality, user_name, group_name)
        user_prompt = get_tutor_greeting_user_prompt(user_name, group_name)
        
        greeting = generate_ai_response(system_prompt, user_prompt, temperature=0.9)
        
        logger.info(f"✅ Generated greeting ({len(greeting)} chars)")
        
        # Create message in Firestore
        db = firestore.client()
        message_ref = db.collection("conversations").document(conversation_id).collection("messages").document()
        
        message_data = {
            "id": message_ref.id,
            "conversationId": conversation_id,
            "senderId": tutor_id,
            "content": greeting,
            "timestamp": firestore.SERVER_TIMESTAMP,
            "readBy": [tutor_id],
            "deliveredTo": [tutor_id]
        }
        
        message_ref.set(message_data)
        
        # Update conversation's lastMessage
        conversation_ref = db.collection("conversations").document(conversation_id)
        conversation_ref.update({
            "lastMessage": greeting[:100],  # Preview (max 100 chars)
            "lastMessageTimestamp": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP
        })
        
        logger.info(f"✅ Greeting message created: {message_ref.id}")
        
        return https_fn.Response(
            json.dumps({
                "greeting": greeting,
                "message_id": message_ref.id
            }),
            status=200,
            headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
        )
    
    except Exception as e:
        logger.error(f"Error in generate_tutor_greeting: {e}", exc_info=True)
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
        )


@https_fn.on_request(cors=options.CorsOptions(
    cors_origins=Config.CORS_ORIGINS,
    cors_methods=Config.CORS_METHODS
))
def generate_tutor_response(req: https_fn.Request) -> https_fn.Response:
    """
    Generate an AI response from a tutor based on conversation history and their personality.
    
    This endpoint is called when a user sends a message in a conversation with a tutor.
    The tutor will respond based on their personality, the conversation context, and their
    teaching/guiding approach.
    
    Request Body:
    {
        "tutor_id": "tutor_abc123",
        "tutor_personality": "A friendly Spanish teacher from Barcelona...",
        "tutor_name": "Sofia Martinez",
        "conversation_history": [
            {"sender_id": "tutor_123", "sender_name": "Sofia", "content": "¡Hola! ...", "timestamp": "..."},
            {"sender_id": "user_456", "sender_name": "John", "content": "Hi! I want to learn Spanish", "timestamp": "..."}
        ],
        "conversation_id": "conv_xyz789"
    }
    
    Response:
    {
        "response": "¡Excelente! I'm so excited to help you learn Spanish...",
        "message_id": "msg_def456"
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
        
        tutor_id = data.get("tutor_id", "").strip()
        tutor_personality = data.get("tutor_personality", "").strip()
        tutor_name = data.get("tutor_name", "").strip()
        conversation_history = data.get("conversation_history", [])
        conversation_id = data.get("conversation_id", "").strip()
        
        if not tutor_id or not tutor_personality or not tutor_name or not conversation_id:
            return https_fn.Response(
                json.dumps({"error": "tutor_id, tutor_personality, tutor_name, and conversation_id are required"}),
                status=400,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
            )
        
        if not conversation_history:
            return https_fn.Response(
                json.dumps({"error": "conversation_history is required and cannot be empty"}),
                status=400,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
            )
        
        logger.info(f"🎓 Generating response from tutor {tutor_name} for conversation {conversation_id}")
        
        if not Config.OPENAI_API_KEY:
            logger.error("OPENAI_API_KEY not set in environment")
            return https_fn.Response(
                json.dumps({"error": "OpenAI API key not configured"}),
                status=500,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
            )
        
        # Create tutor response prompt
        system_prompt = get_tutor_response_system_prompt(tutor_name, tutor_personality)

        # Format conversation history for context
        formatted_history = []
        for msg in conversation_history[-10:]:  # Last 10 messages for context
            sender_name = msg.get("sender_name", "Unknown")
            content = msg.get("content", "")
            formatted_history.append(f"{sender_name}: {content}")
        
        conversation_context = "\n".join(formatted_history)
        
        user_prompt = get_tutor_response_user_prompt(conversation_context)
        
        tutor_response = generate_ai_response(system_prompt, user_prompt, temperature=0.85)
        
        logger.info(f"✅ Generated response ({len(tutor_response)} chars)")
        
        # Create message in Firestore
        db = firestore.client()
        message_ref = db.collection("conversations").document(conversation_id).collection("messages").document()
        
        message_data = {
            "id": message_ref.id,
            "conversationId": conversation_id,
            "senderId": tutor_id,
            "content": tutor_response,
            "timestamp": firestore.SERVER_TIMESTAMP,
            "readBy": [tutor_id],
            "deliveredTo": [tutor_id]
        }
        
        message_ref.set(message_data)
        
        # Update conversation's lastMessage
        conversation_ref = db.collection("conversations").document(conversation_id)
        conversation_ref.update({
            "lastMessage": tutor_response[:100],  # Preview (max 100 chars)
            "lastMessageTimestamp": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP
        })
        
        logger.info(f"✅ Response message created: {message_ref.id}")
        
        return https_fn.Response(
            json.dumps({
                "response": tutor_response,
                "message_id": message_ref.id
            }),
            status=200,
            headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
        )
    
    except Exception as e:
        logger.error(f"Error in generate_tutor_response: {e}", exc_info=True)
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": Config.CORS_ORIGINS}
        )
