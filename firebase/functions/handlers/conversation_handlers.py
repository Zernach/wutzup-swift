"""
Conversation-related Firebase Cloud Function handlers.
"""
import logging
from firebase_functions import firestore_fn

logger = logging.getLogger(__name__)

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
    
    # For now, users will see new conversations when they check their chat list


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
