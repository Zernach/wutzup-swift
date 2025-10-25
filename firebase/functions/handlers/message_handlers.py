"""
Message-related Firebase Cloud Function handlers.
"""
import logging
from firebase_functions import firestore_fn
from firebase_admin import firestore
from utils.notification_utils import send_message_notification

logger = logging.getLogger(__name__)

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
            send_message_notification(
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
