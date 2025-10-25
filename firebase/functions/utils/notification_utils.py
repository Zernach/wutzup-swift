"""
Notification utilities for Firebase Cloud Functions.
"""
import logging
from typing import Optional
from firebase_admin import firestore, messaging
from config import Config

logger = logging.getLogger(__name__)

def send_message_notification(
    db: firestore.Client,
    recipient_id: str,
    sender_name: str,
    message_content: str,
    conversation_id: str,
    message_id: str,
    is_group: bool = False
) -> bool:
    """
    Send push notification to a single recipient.
    
    Args:
        db: Firestore client
        recipient_id: ID of the recipient
        sender_name: Name of the sender
        message_content: Content of the message
        conversation_id: ID of the conversation
        message_id: ID of the message
        is_group: Whether this is a group conversation
        
    Returns:
        True if notification was sent successfully, False otherwise
    """
    try:
        # Get recipient's FCM token
        recipient_ref = db.collection("users").document(recipient_id)
        recipient = recipient_ref.get()
        
        if not recipient.exists:
            logger.warning(f"Recipient {recipient_id} not found")
            return False
        
        recipient_data = recipient.to_dict()
        fcm_token = recipient_data.get("fcmToken")
        
        if not fcm_token:
            logger.info(f"No FCM token for recipient {recipient_id}")
            return False
        
        # Truncate message content for notification
        preview = message_content[:Config.NOTIFICATION_PREVIEW_LENGTH]
        if len(message_content) > Config.NOTIFICATION_PREVIEW_LENGTH:
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
        return True
        
    except Exception as e:
        logger.error(f"Error sending notification to {recipient_id}: {e}", exc_info=True)
        return False
