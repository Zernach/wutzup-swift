"""
Cloud Functions for Wutzup Messaging App

This module contains Firebase Cloud Functions for handling:
- Push notifications when messages are created
- User presence tracking
- Conversation updates
- AI-powered response suggestions
"""

from firebase_functions import firestore_fn, https_fn, options
from firebase_admin import initialize_app, firestore, messaging, storage
from google.cloud.firestore_v1.base_query import FieldFilter
from typing import Any, List, Dict
import logging
import os
import json
import io
import tempfile
from datetime import datetime

# Load environment variables from .env file
from dotenv import load_dotenv
load_dotenv()

# LangChain imports
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage

# OpenAI for DALL-E and research
from openai import OpenAI

# PIL for image processing
from PIL import Image
import requests

# Beautiful Soup for web scraping
from bs4 import BeautifulSoup

# Initialize Firebase Admin SDK
app = initialize_app()

# Configure global options
options.set_global_options(max_instances=10)

# Setup logging
logger = logging.getLogger(__name__)


# ============================================================================
# Message Triggers
# ============================================================================

@firestore_fn.on_document_created(
    document="conversations/{conversationId}/messages/{messageId}"
)
def on_message_created(
    event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None],
) -> None:
    """
    Triggered when a new message is created.
    
    Actions:
    1. Update conversation's lastMessage and lastMessageTimestamp
    2. Send push notifications to all recipients (except sender)
    3. Update message deliveredTo array
    """
    if not event.data:
        logger.warning("No data in event")
        return
    
    # Get message data
    message_data = event.data.to_dict()
    if not message_data:
        logger.warning("Message data is empty")
        return
    
    conversation_id = event.params["conversationId"]
    message_id = event.params["messageId"]
    sender_id = message_data.get("senderId")
    content = message_data.get("content", "")
    
    logger.info(f"New message {message_id} in conversation {conversation_id}")
    
    db = firestore.client()
    
    try:
        # 1. Get conversation to find recipients
        conversation_ref = db.collection("conversations").document(conversation_id)
        conversation = conversation_ref.get()
        
        if not conversation.exists:
            logger.error(f"Conversation {conversation_id} not found")
            return
        
        conversation_data = conversation.to_dict()
        participant_ids = conversation_data.get("participantIds", [])
        is_group = conversation_data.get("isGroup", False)
        
        # 2. Get sender information
        sender_ref = db.collection("users").document(sender_id)
        sender = sender_ref.get()
        sender_data = sender.to_dict() if sender.exists else {}
        sender_name = sender_data.get("displayName", "Someone")
        
        # 3. Send notification to each recipient (except sender)
        recipients = [uid for uid in participant_ids if uid != sender_id]
        
        for recipient_id in recipients:
            _send_message_notification(
                db=db,
                recipient_id=recipient_id,
                sender_name=sender_name,
                message_content=content,
                conversation_id=conversation_id,
                message_id=message_id,
                is_group=is_group
            )
        
        logger.info(f"Sent notifications to {len(recipients)} recipients")
        
    except Exception as e:
        logger.error(f"Error processing message: {e}", exc_info=True)


def _send_message_notification(
    db: firestore.Client,
    recipient_id: str,
    sender_name: str,
    message_content: str,
    conversation_id: str,
    message_id: str,
    is_group: bool = False
) -> None:
    """
    Send push notification to a single recipient.
    """
    try:
        # Get recipient's FCM token
        recipient_ref = db.collection("users").document(recipient_id)
        recipient = recipient_ref.get()
        
        if not recipient.exists:
            logger.warning(f"Recipient {recipient_id} not found")
            return
        
        recipient_data = recipient.to_dict()
        fcm_token = recipient_data.get("fcmToken")
        
        if not fcm_token:
            logger.info(f"No FCM token for recipient {recipient_id}")
            return
        
        # Truncate message content for notification
        preview = message_content[:100]
        if len(message_content) > 100:
            preview += "..."
        
        # Create title and body
        title = f"Wutzup from {sender_name}"
        body = preview
        
        # Create notification
        notification = messaging.Notification(
            title=title,
            body=body  # For Android compatibility
        )
        
        # Create message
        message = messaging.Message(
            notification=notification,
            data={
                "conversationId": conversation_id,
                "messageId": message_id,
                "senderId": sender_name,
                "type": "new_message"
            },
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        alert=messaging.ApsAlert(
                            title=title,
                            body=body
                        ),
                        badge=1,  # Increment badge
                        sound="default",
                        content_available=True
                    )
                )
            ),
            token=fcm_token
        )
        
        # Send notification
        response = messaging.send(message)
        logger.info(f"Notification sent to {recipient_id}: {response}")
        
    except Exception as e:
        logger.error(f"Error sending notification to {recipient_id}: {e}", exc_info=True)


# ============================================================================
# Conversation Triggers
# ============================================================================

@firestore_fn.on_document_created(
    document="conversations/{conversationId}"
)
def on_conversation_created(
    event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None],
) -> None:
    """
    Triggered when a new conversation is created.
    
    Actions:
    1. Initialize presence for all participants
    2. Send notifications to participants (except creator)
    """
    if not event.data:
        return
    
    conversation_data = event.data.to_dict()
    if not conversation_data:
        return
    
    conversation_id = event.params["conversationId"]
    participant_ids = conversation_data.get("participantIds", [])
    is_group = conversation_data.get("isGroup", False)
    
    logger.info(f"New conversation {conversation_id} with {len(participant_ids)} participants")
    
    # Note: Participant notifications can be added here if needed
    # For now, users will see new conversations when they check their chat list


# ============================================================================
# User Presence Triggers
# ============================================================================

@firestore_fn.on_document_written(
    document="presence/{userId}"
)
def on_presence_updated(
    event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot | None]],
) -> None:
    """
    Triggered when user presence is updated.
    
    Actions:
    1. Log presence changes for debugging
    2. Future: Send presence notifications to contacts
    """
    user_id = event.params["userId"]
    
    before = event.data.before.to_dict() if event.data.before else None
    after = event.data.after.to_dict() if event.data.after else None
    
    if before and after:
        old_status = before.get("status")
        new_status = after.get("status")
        
        if old_status != new_status:
            logger.info(f"User {user_id} status changed: {old_status} -> {new_status}")


# ============================================================================
# HTTP Functions (for testing/utilities)
# ============================================================================

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


# ============================================================================
# Translation (HTTP)
# ============================================================================

@https_fn.on_request(cors=options.CorsOptions(
    cors_origins="*",
    cors_methods=["POST", "OPTIONS"]
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
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "POST, OPTIONS",
                    "Access-Control-Allow-Headers": "Content-Type",
                    "Access-Control-Max-Age": "3600"
                }
            )

        data = req.get_json()
        if not data:
            return https_fn.Response(
                json.dumps({"error": "Missing request body"}),
                status=400,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"}
            )

        text = (data.get("text") or "").strip()
        target_language = (data.get("target_language") or "").strip()
        source_language = (data.get("source_language") or "").strip()

        if not text or not target_language:
            return https_fn.Response(
                json.dumps({"error": "Both 'text' and 'target_language' are required"}),
                status=400,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"}
            )

        openai_api_key = os.environ.get("OPENAI_API_KEY")
        if not openai_api_key:
            logger.error("OPENAI_API_KEY not set in environment")
            return https_fn.Response(
                json.dumps({"error": "OpenAI API key not configured"}),
                status=500,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"}
            )

        system_prompt = """You are a professional translator. Translate the user's text to the requested target language.
Follow these rules strictly:
- Preserve the original meaning, tone, and nuance.
- Use natural, conversational phrasing for the target language.
- Do not add explanations.
- If the text includes slang, emojis, or idioms, adapt them appropriately to sound natural.
- Return ONLY valid JSON with keys 'translated_text' and 'detected_language' (ISO 639-1 code)."""

        # Build user prompt
        src_info = f" (source: {source_language})" if source_language else ""
        user_prompt = f"Target language: {target_language}{src_info}\n\nText to translate:\n{text}"

        llm = ChatOpenAI(
            model="gpt-4o-mini",
            temperature=0.2,
            openai_api_key=openai_api_key
        )

        messages = [
            SystemMessage(content=system_prompt),
            HumanMessage(content=user_prompt)
        ]
        response = llm.invoke(messages)
        response_text = response.content

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
            headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"}
        )

    except Exception as e:
        logger.error(f"Error in translate_text: {e}", exc_info=True)
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"}
        )


# ============================================================================
# Message Cultural Context (HTTP)
# ============================================================================

@https_fn.on_request(cors=options.CorsOptions(
    cors_origins="*",
    cors_methods=["POST", "OPTIONS"]
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
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "POST, OPTIONS",
                    "Access-Control-Allow-Headers": "Content-Type",
                    "Access-Control-Max-Age": "3600"
                }
            )

        data = req.get_json()
        if not data:
            return https_fn.Response(
                json.dumps({"error": "Missing request body"}),
                status=400,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"}
            )

        selected_message = (data.get("selected_message") or "").strip()
        conversation_history = data.get("conversation_history") or []

        if not selected_message:
            return https_fn.Response(
                json.dumps({"error": "'selected_message' is required"}),
                status=400,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"}
            )

        openai_api_key = os.environ.get("OPENAI_API_KEY")
        if not openai_api_key:
            logger.error("OPENAI_API_KEY not set in environment")
            return https_fn.Response(
                json.dumps({"error": "OpenAI API key not configured"}),
                status=500,
                headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"}
            )

        # Build conversation text
        history_text = "\n".join([
            f"{'You' if (m.get('is_from_current_user') or False) else (m.get('sender_name') or 'Unknown')}: {m.get('content') or ''}"
            for m in conversation_history[-10:]
        ])

        system_prompt = """You are a culturally-aware messaging assistant.
Given a selected message and (optionally) surrounding conversation messages, provide concise, practical context to help the user interpret it correctly.

Include:
- Tone and likely intent (brief)
- Cultural or regional nuances (idioms, emoji usage, politeness levels)
- Potential misinterpretations to avoid
- If helpful, one-liner suggestion for a respectful reply

Return ONLY valid JSON with key 'context'. Keep it to 6-10 bullet points or short paragraphs (<= 160 words). Avoid fluff."""

        user_prompt = f"""Selected message:
"{selected_message}"

Conversation (most recent up to 10):
{history_text if history_text else '(no additional context provided)'}

Provide the cultural/contextual analysis as specified."""

        llm = ChatOpenAI(
            model="gpt-4o-mini",
            temperature=0.4,
            openai_api_key=openai_api_key
        )

        messages = [
            SystemMessage(content=system_prompt),
            HumanMessage(content=user_prompt)
        ]
        response = llm.invoke(messages)
        response_text = response.content

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
            context = data_out.get("context")
            if not context:
                raise ValueError("Missing 'context'")
        except Exception as e:
            logger.warning(f"Failed to parse JSON; returning raw text. Error: {e}")
            context = response_text.strip()

        return https_fn.Response(
            json.dumps({"context": context}),
            status=200,
            headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"}
        )

    except Exception as e:
        logger.error(f"Error in message_context: {e}", exc_info=True)
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"}
        )


# ============================================================================
# AI Response Generation (LangChain + OpenAI)
# ============================================================================

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
        
        # Get OpenAI API key from environment variable
        # Set this with: firebase functions:config:set openai.api_key="your-key-here"
        openai_api_key = os.environ.get("OPENAI_API_KEY")
        
        if not openai_api_key:
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
        system_prompt = """You are a helpful AI assistant that generates response suggestions for messaging conversations.
Your task is to generate TWO different response options based on the conversation history.

In the conversation history:
- Messages labeled "You" are from the USER who is requesting suggestions
- All other messages are from OTHER PARTICIPANTS in the conversation
- You are generating responses FOR the user (labeled "You")

Generate these TWO response options:

1. A POSITIVE response: Agreeable, enthusiastic, accepting the proposal/question
2. A NEGATIVE response: Polite decline, suggesting alternative, or gentle rejection

Both responses should:
- Match the user's personality if provided
- Be natural and conversational
- Be appropriate length (1-3 sentences)
- Sound authentic, not robotic
- Consider the context of the conversation
- Respond to what OTHER PARTICIPANTS have said
- If no other users have said anything, then generate a response that is contextual and reflects a logical next message from the current user.

Return ONLY a valid JSON object with this exact structure:
{
  "positive_response": "your positive response here",
  "negative_response": "your negative response here"
}"""
        
        user_prompt = f"""Conversation history:
{conversation_text}
{personality_context}

Generate two response options (positive and negative) that the user could send next."""
        
        # Initialize ChatOpenAI
        llm = ChatOpenAI(
            model="gpt-4o-mini",
            temperature=0.7,
            openai_api_key=openai_api_key
        )
        
        # Generate responses
        messages = [
            SystemMessage(content=system_prompt),
            HumanMessage(content=user_prompt)
        ]
        
        response = llm.invoke(messages)
        response_text = response.content
        
        logger.info(f"OpenAI response: {response_text}")
        
        # Parse JSON response
        try:
            # Try to extract JSON if wrapped in markdown code blocks
            if "```json" in response_text:
                json_start = response_text.find("```json") + 7
                json_end = response_text.find("```", json_start)
                response_text = response_text[json_start:json_end].strip()
            elif "```" in response_text:
                json_start = response_text.find("```") + 3
                json_end = response_text.find("```", json_start)
                response_text = response_text[json_start:json_end].strip()
            
            response_data = json.loads(response_text)
            
            # Validate response structure
            if "positive_response" not in response_data or "negative_response" not in response_data:
                raise ValueError("Invalid response structure")
            
            return https_fn.Response(
                json.dumps(response_data),
                status=200,
                headers={"Content-Type": "application/json"}
            )
            
        except (json.JSONDecodeError, ValueError) as e:
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


# ============================================================================
# GIF Generation (DALL-E)
# ============================================================================

@https_fn.on_request(cors=options.CorsOptions(
    cors_origins="*",
    cors_methods=["POST", "OPTIONS"]
))
def generate_gif(req: https_fn.Request) -> https_fn.Response:
    """
    Generate a GIF from two DALL-E images.
    
    This function:
    1. Generates 2 images using DALL-E 3
    2. Converts to animated GIF format
    3. Uploads to Firebase Storage
    4. Returns the public URL
    
    Request Body:
    {
        "prompt": "a cat dancing under disco lights"
    }
    
    Response:
    {
        "gif_url": "https://storage.googleapis.com/.../animated.gif",
        "frames_generated": 2
    }
    """
    try:
        # Handle CORS preflight
        if req.method == "OPTIONS":
            return https_fn.Response(
                status=204,
                headers={
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "POST, OPTIONS",
                    "Access-Control-Allow-Headers": "Content-Type",
                    "Access-Control-Max-Age": "3600"
                }
            )
        
        # Parse request
        data = req.get_json()
        
        if not data or "prompt" not in data:
            return https_fn.Response(
                json.dumps({"error": "Missing 'prompt' in request body"}),
                status=400,
                headers={
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*"
                }
            )
        
        prompt = data.get("prompt")
        
        if not prompt or len(prompt.strip()) == 0:
            return https_fn.Response(
                json.dumps({"error": "Prompt cannot be empty"}),
                status=400,
                headers={
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*"
                }
            )
        
        logger.info(f"🎬 Generating GIF with prompt: {prompt}")
        
        # Get OpenAI API key
        openai_api_key = os.environ.get("OPENAI_API_KEY")
        
        if not openai_api_key:
            logger.error("OPENAI_API_KEY not set in environment")
            return https_fn.Response(
                json.dumps({"error": "OpenAI API key not configured"}),
                status=500,
                headers={
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*"
                }
            )
        
        # Initialize OpenAI client
        client = OpenAI(api_key=openai_api_key)
        
        # Generate 2 frames with DALL-E
        frames = []
        
        logger.info(f"🎨 Generating 2 frames...")
        
        # Generate frame 1
        try:
            logger.info(f"  🎨 Generating frame 1...")
            response = client.images.generate(
                model="dall-e-3",
                prompt=f"{prompt}, first frame",
                size="1024x1024",
                quality="standard",
                n=1
            )
            
            # Get image URL
            image_url = response.data[0].url
            
            # Download image
            img_response = requests.get(image_url)
            img_response.raise_for_status()
            
            # Load image
            img = Image.open(io.BytesIO(img_response.content))
            
            # Resize to optimize GIF size (512x512)
            img = img.resize((512, 512), Image.Resampling.LANCZOS)
            
            frames.append(img)
            
            logger.info(f"  ✅ Frame 1 generated")
            
        except Exception as e:
            logger.error(f"  ❌ Error generating frame 1: {e}")
            raise Exception(f"Failed to generate frame 1: {e}")
        
        # Generate frame 2
        try:
            logger.info(f"  🎨 Generating frame 2...")
            response = client.images.generate(
                model="dall-e-3",
                prompt=f"{prompt}, second frame, slight variation",
                size="1024x1024",
                quality="standard",
                n=1
            )
            
            # Get image URL
            image_url = response.data[0].url
            
            # Download image
            img_response = requests.get(image_url)
            img_response.raise_for_status()
            
            # Load image
            img = Image.open(io.BytesIO(img_response.content))
            
            # Resize to optimize GIF size (512x512)
            img = img.resize((512, 512), Image.Resampling.LANCZOS)
            
            frames.append(img)
            
            logger.info(f"  ✅ Frame 2 generated")
            
        except Exception as e:
            logger.error(f"  ❌ Error generating frame 2: {e}")
            raise Exception(f"Failed to generate frame 2: {e}")
        
        logger.info(f"✅ Generated 2 frames successfully")
        
        # Convert to GIF
        logger.info("🎞️ Converting to animated GIF format...")
        
        with tempfile.NamedTemporaryFile(suffix=".gif", delete=False) as temp_file:
            gif_path = temp_file.name
            
            # Save as animated GIF with 2 frames
            frames[0].save(
                gif_path,
                format='GIF',
                save_all=True,
                append_images=[frames[1]],
                duration=500,  # 500ms per frame
                loop=0,  # Loop forever
                optimize=False
            )
        
        logger.info(f"✅ GIF created: {gif_path}")
        
        # Upload to Firebase Storage
        logger.info("☁️ Uploading to Firebase Storage...")
        
        bucket = storage.bucket()
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        blob_name = f"gifs/generated_{timestamp}.gif"
        blob = bucket.blob(blob_name)
        
        # Upload file
        blob.upload_from_filename(gif_path, content_type="image/gif")
        
        # Make publicly accessible
        blob.make_public()
        
        # Get public URL
        gif_url = blob.public_url
        
        logger.info(f"✅ GIF uploaded: {gif_url}")
        
        # Clean up temp file
        try:
            os.unlink(gif_path)
        except:
            pass
        
        # Return response
        return https_fn.Response(
            json.dumps({
                "gif_url": gif_url,
                "frames_generated": 2
            }),
            status=200,
            headers={
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            }
        )
        
    except Exception as e:
        logger.error(f"❌ Error in generate_gif: {e}", exc_info=True)
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            }
        )


# ============================================================================
# Web Research (Search + AI Summarization)
# ============================================================================

@https_fn.on_request(cors=options.CorsOptions(
    cors_origins="*",
    cors_methods=["POST", "OPTIONS"]
))
def conduct_research(req: https_fn.Request) -> https_fn.Response:
    """
    Conduct web research on a given prompt.
    
    This function:
    1. Searches DuckDuckGo for relevant information
    2. Scrapes content from top results
    3. Uses OpenAI GPT to summarize the findings
    4. Returns a comprehensive summary
    
    Request Body:
    {
        "prompt": "What are the latest developments in renewable energy?"
    }
    
    Response:
    {
        "summary": "Based on recent research..."
    }
    """
    try:
        # Handle CORS preflight
        if req.method == "OPTIONS":
            return https_fn.Response(
                status=204,
                headers={
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "POST, OPTIONS",
                    "Access-Control-Allow-Headers": "Content-Type",
                    "Access-Control-Max-Age": "3600"
                }
            )
        
        # Parse request
        data = req.get_json()
        
        if not data or "prompt" not in data:
            return https_fn.Response(
                json.dumps({"error": "Missing 'prompt' in request body"}),
                status=400,
                headers={
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*"
                }
            )
        
        prompt = data.get("prompt")
        
        if not prompt or len(prompt.strip()) == 0:
            return https_fn.Response(
                json.dumps({"error": "Prompt cannot be empty"}),
                status=400,
                headers={
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*"
                }
            )
        
        logger.info(f"🔍 Conducting research: {prompt}")
        
        # Get OpenAI API key
        openai_api_key = os.environ.get("OPENAI_API_KEY")
        
        if not openai_api_key:
            logger.error("OPENAI_API_KEY not set in environment")
            return https_fn.Response(
                json.dumps({"error": "OpenAI API key not configured"}),
                status=500,
                headers={
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*"
                }
            )
        
        # Step 1: Search DuckDuckGo for results
        logger.info("🌐 Searching DuckDuckGo...")
        search_results = _search_duckduckgo(prompt)
        
        if not search_results:
            logger.warning("No search results found")
            return https_fn.Response(
                json.dumps({
                    "summary": "I couldn't find any relevant information for your query. Please try rephrasing your question or search for something else."
                }),
                status=200,
                headers={
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*"
                }
            )
        
        logger.info(f"✅ Found {len(search_results)} search results")
        
        # Step 2: Scrape content from top results (limit to 3)
        logger.info("📄 Scraping content from top results...")
        scraped_content = []
        for i, result in enumerate(search_results[:3]):
            try:
                content = _scrape_webpage(result['url'])
                if content:
                    scraped_content.append({
                        'title': result['title'],
                        'url': result['url'],
                        'content': content[:1000]  # Limit to 1000 chars per page
                    })
                    logger.info(f"  ✅ Scraped: {result['title']}")
            except Exception as e:
                logger.warning(f"  ❌ Failed to scrape {result['url']}: {e}")
                continue
        
        if not scraped_content:
            logger.warning("No content could be scraped")
            return https_fn.Response(
                json.dumps({
                    "summary": "I found some results but couldn't access their content. This might be due to website restrictions. Please try a different query."
                }),
                status=200,
                headers={
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*"
                }
            )
        
        logger.info(f"✅ Scraped {len(scraped_content)} pages")
        
        # Step 3: Use OpenAI to summarize the findings
        logger.info("🤖 Generating AI summary...")
        
        # Prepare context for AI
        context = "\n\n".join([
            f"Source: {item['title']}\nURL: {item['url']}\nContent: {item['content']}"
            for item in scraped_content
        ])
        
        # Create LangChain prompt
        system_prompt = """You are a helpful research assistant. Your task is to summarize web search results in a clear, comprehensive, and accurate manner.

Guidelines:
- Synthesize information from multiple sources
- Provide factual, objective information
- Include specific details and examples when available
- Organize information logically
- Keep the summary concise but informative (200-400 words)
- Cite sources when mentioning specific claims
- If information is conflicting, mention both perspectives
- IMPORTANT: Do not mention your training date or knowledge cutoff. All information is from live web searches, not your training data.
"""
        
        user_prompt = f"""Research question: {prompt}

Here are the search results I found:

{context}

Please provide a comprehensive summary that answers the research question based on these sources."""
        
        # Initialize ChatOpenAI
        llm = ChatOpenAI(
            model="gpt-4o-mini",
            temperature=0.7,
            openai_api_key=openai_api_key
        )
        
        # Generate summary
        messages = [
            SystemMessage(content=system_prompt),
            HumanMessage(content=user_prompt)
        ]
        
        response = llm.invoke(messages)
        summary = response.content
        
        logger.info(f"✅ Research complete!")
        logger.info(f"   Summary length: {len(summary)} characters")
        
        # Return response
        return https_fn.Response(
            json.dumps({
                "summary": summary,
                "sources": [{"title": item['title'], "url": item['url']} for item in scraped_content]
            }),
            status=200,
            headers={
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            }
        )
        
    except Exception as e:
        logger.error(f"❌ Error in conduct_research: {e}", exc_info=True)
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            }
        )


def _search_duckduckgo(query: str, max_results: int = 5) -> List[Dict[str, str]]:
    """
    Search DuckDuckGo and return results.
    
    Returns:
        List of dicts with 'title', 'url', 'snippet'
    """
    try:
        # Use DuckDuckGo HTML search (no API key needed)
        search_url = "https://html.duckduckgo.com/html/"
        params = {
            'q': query,
            'kl': 'us-en'  # Region
        }
        
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        
        response = requests.post(search_url, data=params, headers=headers, timeout=10)
        response.raise_for_status()
        
        # Parse HTML
        soup = BeautifulSoup(response.text, 'html.parser')
        
        results = []
        for result_div in soup.find_all('div', class_='result', limit=max_results):
            try:
                # Extract title and URL
                title_tag = result_div.find('a', class_='result__a')
                if not title_tag:
                    continue
                
                title = title_tag.get_text(strip=True)
                url = title_tag.get('href', '')
                
                # Clean URL (DuckDuckGo wraps URLs)
                if url.startswith('//duckduckgo.com/l/?uddg='):
                    # Extract actual URL from redirect
                    import urllib.parse
                    url = urllib.parse.unquote(url.split('uddg=')[1].split('&')[0])
                
                # Extract snippet
                snippet_tag = result_div.find('a', class_='result__snippet')
                snippet = snippet_tag.get_text(strip=True) if snippet_tag else ""
                
                if url and not url.startswith('http'):
                    url = 'https:' + url
                
                results.append({
                    'title': title,
                    'url': url,
                    'snippet': snippet
                })
                
            except Exception as e:
                logger.warning(f"Error parsing search result: {e}")
                continue
        
        return results
        
    except Exception as e:
        logger.error(f"Error searching DuckDuckGo: {e}")
        return []


def _scrape_webpage(url: str, timeout: int = 10) -> str:
    """
    Scrape text content from a webpage.
    
    Returns:
        Text content of the page
    """
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        
        response = requests.get(url, headers=headers, timeout=timeout)
        response.raise_for_status()
        
        # Parse HTML
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Remove script and style elements
        for script in soup(['script', 'style', 'nav', 'footer', 'header']):
            script.decompose()
        
        # Get text
        text = soup.get_text(separator=' ', strip=True)
        
        # Clean up whitespace
        lines = (line.strip() for line in text.splitlines())
        chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
        text = ' '.join(chunk for chunk in chunks if chunk)
        
        return text
        
    except Exception as e:
        logger.error(f"Error scraping {url}: {e}")
        return ""


# ============================================================================
# Scheduled Functions (Future)
# ============================================================================

# @scheduler_fn.on_schedule(schedule="every 24 hours")
# def cleanup_old_typing_indicators(event: scheduler_fn.ScheduledEvent) -> None:
#     """
#     Clean up old typing indicators (older than 5 minutes).
#     """
#     pass