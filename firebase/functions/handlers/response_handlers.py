"""
AI response generation handlers for Firebase Cloud Functions.
"""
import logging
import json
from firebase_functions import https_fn
from utils.ai_utils import generate_ai_response, extract_json_from_response
from config import Config
from prompts import RESPONSE_SUGGESTIONS_SYSTEM_PROMPT, get_response_suggestions_user_prompt

logger = logging.getLogger(__name__)

@https_fn.on_request()
def generate_response_suggestions(req: https_fn.Request) -> https_fn.Response:
    """
    Generate AI-powered response suggestions using LangChain and OpenAI.
    
    Request Body:
    {
        "conversation_history": [
            {
                "sender_id": "user123",
                "sender_name": "Alice",
                "content": "Hey, want to grab coffee?",
                "timestamp": "2025-10-21T10:00:00Z"
            },
            ...
        ],
        "user_personality": "I'm friendly and casual, like to use emojis"
    }
    
    Response:
    {
        "positive_response": "Sure! I'd love to grab coffee. What time works for you? ☕",
        "negative_response": "Thanks for asking, but I'm pretty busy today. Maybe another time?"
    }
    """
    try:
        # Parse request body
        data = req.get_json()
        
        if not data:
            return https_fn.Response(
                json.dumps({"error": "Missing request body"}),
                status=400,
                headers={"Content-Type": "application/json"}
            )
        
        conversation_history = data.get("conversation_history", [])
        user_personality = data.get("user_personality")
        
        if not conversation_history:
            return https_fn.Response(
                json.dumps({"error": "conversation_history is required"}),
                status=400,
                headers={"Content-Type": "application/json"}
            )
        
        if not Config.OPENAI_API_KEY:
            logger.error("OPENAI_API_KEY not set in environment")
            return https_fn.Response(
                json.dumps({"error": "OpenAI API key not configured"}),
                status=500,
                headers={"Content-Type": "application/json"}
            )
        
        # Format conversation history with current user context
        conversation_text = "\n".join([
            f"{'You' if msg.get('is_from_current_user', False) else msg.get('sender_name', 'Unknown')}: {msg.get('content', '')}"
            for msg in conversation_history[-10:]  # Last 10 messages
        ])
        
        # Build personality context
        personality_context = ""
        if user_personality:
            personality_context = f"\n\nThe user's personality: {user_personality}"
        
        # Create LangChain prompt
        system_prompt = RESPONSE_SUGGESTIONS_SYSTEM_PROMPT
        user_prompt = get_response_suggestions_user_prompt(conversation_text, personality_context)
        
        response_text = generate_ai_response(system_prompt, user_prompt, temperature=0.7)
        
        logger.info(f"OpenAI response: {response_text}")
        
        # Parse JSON response
        try:
            response_data = extract_json_from_response(response_text)
            
            # Validate response structure
            if "positive_response" not in response_data or "negative_response" not in response_data:
                raise ValueError("Invalid response structure")
            
            return https_fn.Response(
                json.dumps(response_data),
                status=200,
                headers={"Content-Type": "application/json"}
            )
            
        except (ValueError, json.JSONDecodeError) as e:
            logger.error(f"Failed to parse OpenAI response: {e}")
            logger.error(f"Raw response: {response_text}")
            
            # Fallback: create structured response from text
            lines = response_text.strip().split("\n")
            positive = ""
            negative = ""
            
            for line in lines:
                if "positive" in line.lower() and not positive:
                    positive = line.split(":", 1)[-1].strip().strip('"')
                elif "negative" in line.lower() and not negative:
                    negative = line.split(":", 1)[-1].strip().strip('"')
            
            if positive and negative:
                return https_fn.Response(
                    json.dumps({
                        "positive_response": positive,
                        "negative_response": negative
                    }),
                    status=200,
                    headers={"Content-Type": "application/json"}
                )
            else:
                return https_fn.Response(
                    json.dumps({"error": "Failed to parse AI response"}),
                    status=500,
                    headers={"Content-Type": "application/json"}
                )
        
    except Exception as e:
        logger.error(f"Error in generate_response_suggestions: {e}", exc_info=True)
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={"Content-Type": "application/json"}
        )
