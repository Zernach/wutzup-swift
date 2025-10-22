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

# OpenAI for DALL-E
from openai import OpenAI

# PIL for image processing
from PIL import Image
import requests

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
        
        # Format conversation history
        conversation_text = "\n".join([
            f"{msg.get('sender_name', 'Unknown')}: {msg.get('content', '')}"
            for msg in conversation_history[-10:]  # Last 10 messages
        ])
        
        # Build personality context
        personality_context = ""
        if user_personality:
            personality_context = f"\n\nThe user's personality: {user_personality}"
        
        # Create LangChain prompt
        system_prompt = """You are a helpful AI assistant that generates response suggestions for messaging conversations.
Your task is to generate TWO different response options based on the conversation history:

1. A POSITIVE response: Agreeable, enthusiastic, accepting the proposal/question
2. A NEGATIVE response: Polite decline, suggesting alternative, or gentle rejection

Both responses should:
- Match the user's personality if provided
- Be natural and conversational
- Be appropriate length (1-3 sentences)
- Sound authentic, not robotic
- Consider the context of the conversation

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
    Generate a GIF from a single DALL-E image.
    
    This function:
    1. Generates 1 image using DALL-E 3
    2. Converts to GIF format
    3. Uploads to Firebase Storage
    4. Returns the public URL
    
    Request Body:
    {
        "prompt": "a cat dancing under disco lights"
    }
    
    Response:
    {
        "gif_url": "https://storage.googleapis.com/.../animated.gif",
        "frames_generated": 20
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
        
        # Generate 1 frame with DALL-E (convert single image to GIF)
        frames = []
        
        logger.info(f"🎨 Generating image...")
        
        try:
            # Generate image with DALL-E 3
            response = client.images.generate(
                model="dall-e-3",
                prompt=prompt,
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
            
            logger.info(f"  ✅ Image generated")
            
        except Exception as e:
            logger.error(f"  ❌ Error generating image: {e}")
            raise Exception(f"Failed to generate image: {e}")
        
        logger.info(f"✅ Generated image successfully")
        
        # Convert to GIF
        logger.info("🎞️ Converting to GIF format...")
        
        with tempfile.NamedTemporaryFile(suffix=".gif", delete=False) as temp_file:
            gif_path = temp_file.name
            
            # Save as GIF (single frame)
            frames[0].save(
                gif_path,
                format='GIF',
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
                "frames_generated": 1
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
# Scheduled Functions (Future)
# ============================================================================

# @scheduler_fn.on_schedule(schedule="every 24 hours")
# def cleanup_old_typing_indicators(event: scheduler_fn.ScheduledEvent) -> None:
#     """
#     Clean up old typing indicators (older than 5 minutes).
#     """
#     pass