"""
Cloud Functions for Wutzup Messaging App

This module contains Firebase Cloud Functions for handling:
- Push notifications when messages are created
- User presence tracking
- Conversation updates
"""

from firebase_functions import firestore_fn, https_fn, options
from firebase_admin import initialize_app, firestore, messaging
from google.cloud.firestore_v1.base_query import FieldFilter
from typing import Any
import logging

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
        
        # Create notification
        notification = messaging.Notification(
            title=sender_name,
            body=preview
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
# Scheduled Functions (Future)
# ============================================================================

# @scheduler_fn.on_schedule(schedule="every 24 hours")
# def cleanup_old_typing_indicators(event: scheduler_fn.ScheduledEvent) -> None:
#     """
#     Clean up old typing indicators (older than 5 minutes).
#     """
#     pass