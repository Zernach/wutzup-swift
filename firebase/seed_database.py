#!/usr/bin/env python3
"""
Firestore Database Seeding Script for Wutzup

This script initializes the Firestore database with test data for development and testing.
It fetches existing Firebase Authentication users and creates family-friendly conversations.

Usage:
    python seed_database.py --project-id YOUR_PROJECT_ID
    python seed_database.py --emulator  # Use local emulator
"""

import argparse
import os
import sys
from datetime import datetime, timedelta
from typing import List, Dict, Any
import uuid
import random

try:
    import firebase_admin
    from firebase_admin import credentials, firestore, auth
    from google.cloud.firestore_v1 import SERVER_TIMESTAMP
except ImportError:
    sys.exit(1)


class FirestoreSeeder:
    """Seed Firestore database with test data."""
    
    def __init__(self, use_emulator: bool = False):
        """
        Initialize Firestore seeder.
        
        Args:
            use_emulator: If True, connect to local emulator instead of production
        """
        self.use_emulator = use_emulator
        self.db = None
        self.test_users = []
        self.test_conversations = []
        
    def initialize_firestore(self, project_id: str = None):
        """Initialize Firebase Admin SDK and Firestore client."""
        
        if self.use_emulator:
            # Use emulator
            os.environ["FIRESTORE_EMULATOR_HOST"] = "localhost:8080"
            
            if not firebase_admin._apps:
                firebase_admin.initialize_app()
        else:
            # Use production/staging
            if not project_id:
                raise ValueError("project_id required when not using emulator")
            
            
            if not firebase_admin._apps:
                cred = credentials.ApplicationDefault()
                firebase_admin.initialize_app(cred, {
                    'projectId': project_id
                })
        
        self.db = firestore.client()
        
    def clear_collections(self):
        """Clear existing test data (use with caution!)."""
        
        collections = ['users', 'conversations', 'presence', 'typing']
        
        for collection_name in collections:
            collection_ref = self.db.collection(collection_name)
            docs = collection_ref.stream()
            
            count = 0
            for doc in docs:
                doc.reference.delete()
                count += 1
            
            if count > 0:
        
        
    def fetch_existing_users(self) -> List[Dict[str, Any]]:
        """
        Fetch all existing Firebase Authentication users.
        
        Returns:
            List of user data dictionaries
        """
        
        try:
            # List all users from Firebase Auth
            page = auth.list_users()
            users = []
            
            while page:
                for user in page.users:
                    user_data = {
                        "id": user.uid,
                        "email": user.email or f"{user.uid}@example.com",
                        "displayName": user.display_name or user.email.split('@')[0] if user.email else f"User {user.uid[:8]}"
                    }
                    users.append(user_data)
                
                # Get next page
                page = page.get_next_page()
            
            if not users:
                return []
            
            self.test_users = [u["id"] for u in users]
            return users
            
        except Exception as e:
            return []
    
    def ensure_users_in_firestore(self, users: List[Dict[str, Any]]):
        """
        Ensure all Firebase Auth users have corresponding Firestore documents.
        
        Args:
            users: List of user data from Firebase Auth
        """
        
        for user_data in users:
            user_id = user_data["id"]
            user_ref = self.db.collection("users").document(user_id)
            user_doc = user_ref.get()
            
            if not user_doc.exists:
                # Create Firestore user document
                firestore_user = {
                    "id": user_id,
                    "email": user_data["email"],
                    "displayName": user_data["displayName"],
                    "profileImageUrl": f"https://i.pravatar.cc/150?u={user_id}",
                    "createdAt": SERVER_TIMESTAMP
                }
                user_ref.set(firestore_user)
            else:
        
        
    def create_test_conversations(self) -> List[str]:
        """
        Create test conversations with family-friendly content.
        Creates at least 10 conversations if enough users exist.
        
        Returns:
            List of conversation IDs
        """
        
        if len(self.test_users) < 2:
            return []
        
        conversations = []
        conv_count = 0
        
        # Get participant names for conversations
        user_names = {}
        for user_id in self.test_users:
            user_doc = self.db.collection("users").document(user_id).get()
            if user_doc.exists:
                user_names[user_id] = user_doc.to_dict().get("displayName", "User")
        
        # Create one-on-one conversations (create multiple if we have enough users)
        num_users = len(self.test_users)
        pairs_to_create = min(10, (num_users * (num_users - 1)) // 2)  # At most 10 pairs
        
        created_pairs = set()
        for i in range(num_users):
            for j in range(i + 1, num_users):
                if len(created_pairs) >= pairs_to_create:
                    break
                    
                user1 = self.test_users[i]
                user2 = self.test_users[j]
                pair = tuple(sorted([user1, user2]))
                
                if pair not in created_pairs:
                    created_pairs.add(pair)
                    conv_id = f"conv_{conv_count}"
                    conv_count += 1
                    
                    participant_names = {
                        user1: user_names.get(user1, "User"),
                        user2: user_names.get(user2, "User")
                    }
                    
                    conversations.append({
                        "id": conv_id,
                        "participantIds": [user1, user2],
                        "participantNames": participant_names,
                        "isGroup": False,
                        "createdAt": SERVER_TIMESTAMP,
                        "updatedAt": SERVER_TIMESTAMP,
                        "unreadCount": 0
                    })
            
            if len(created_pairs) >= pairs_to_create:
                break
        
        # Create group conversations (if we have 3+ users)
        if num_users >= 3:
            group_names = [
                "Family Chat",
                "Weekend Plans",
                "Book Club",
                "Fitness Buddies",
                "Recipe Exchange",
                "Game Night Crew"
            ]
            
            # Create a few group chats
            num_groups = min(3, num_users // 2)  # Create up to 3 groups
            for i in range(num_groups):
                if conv_count >= 15:  # Cap total conversations
                    break
                
                # Select 3-5 random participants
                num_participants = min(random.randint(3, 5), num_users)
                participants = random.sample(self.test_users, num_participants)
                
                participant_names = {
                    uid: user_names.get(uid, "User") for uid in participants
                }
                
                conv_id = f"conv_group_{i}"
                conversations.append({
                    "id": conv_id,
                    "participantIds": participants,
                    "participantNames": participant_names,
                    "isGroup": True,
                    "groupName": group_names[i % len(group_names)],
                    "groupImageUrl": f"https://i.pravatar.cc/150?img={10 + i}",
                    "createdAt": SERVER_TIMESTAMP,
                    "updatedAt": SERVER_TIMESTAMP,
                    "unreadCount": 0
                })
                conv_count += 1
        
        # Save conversations to Firestore
        conversation_ids = []
        for conv_data in conversations:
            conv_id = conv_data["id"]
            self.db.collection("conversations").document(conv_id).set(conv_data)
            conversation_ids.append(conv_id)
            
            if conv_data.get("isGroup"):
                group_label = f" (group: {conv_data.get('groupName')})"
            else:
                group_label = ""
        
        self.test_conversations = conversation_ids
        return conversation_ids
        
    def create_test_messages(self):
        """Create 10+ family-friendly test messages in conversations."""
        
        if not self.test_conversations:
            return
        
        # Family-friendly message templates
        one_on_one_messages = [
            "Hey! How's your day going?",
            "Did you see that amazing sunset yesterday?",
            "I found a great recipe I want to try this weekend!",
            "Thanks for your help with the project!",
            "Hope you're having a wonderful day! 😊",
            "Just finished a great book. Do you have any recommendations?",
            "Want to go for a walk later?",
            "I'm planning a family game night. Are you free Saturday?",
            "The weather is beautiful today!",
            "Just wanted to say hi and see how you're doing!",
            "Did you get a chance to try that new restaurant?",
            "I've been thinking about taking up a new hobby. Any suggestions?",
            "Thanks for being such a great friend!",
            "Hope your week is going well!",
            "Let's catch up soon over coffee!",
        ]
        
        group_messages = [
            "Good morning everyone! Hope you all have a great day!",
            "Anyone up for a weekend hike?",
            "I'm organizing a potluck dinner. Who's interested?",
            "Thanks everyone for making yesterday's event so fun!",
            "Does anyone know a good place for family activities?",
            "I just learned a new card game we should try!",
            "Who wants to join a book club?",
            "Let's plan a picnic for next month!",
            "Has anyone tried the new park that opened downtown?",
            "I'm grateful to have such wonderful friends!",
            "Movie night at my place this Friday?",
            "Anyone interested in starting a running group?",
            "Let's organize a volunteer day!",
            "Thanks for all the birthday wishes!",
            "Who's up for a game of frisbee this weekend?",
        ]
        
        total_messages = 0
        
        # Add messages to each conversation
        for conv_id in self.test_conversations:
            conv_ref = self.db.collection("conversations").document(conv_id)
            conv_doc = conv_ref.get()
            
            if not conv_doc.exists:
                continue
            
            conv_data = conv_doc.to_dict()
            participants = conv_data.get("participantIds", [])
            is_group = conv_data.get("isGroup", False)
            
            # Select appropriate message pool
            message_pool = group_messages if is_group else one_on_one_messages
            
            # Create 3-8 messages per conversation
            num_messages = random.randint(3, 8)
            messages_to_add = random.sample(message_pool, min(num_messages, len(message_pool)))
            
            last_message = ""
            for i, content in enumerate(messages_to_add):
                sender = random.choice(participants)
                msg_id = str(uuid.uuid4())
                
                # Random read status - some read by all, some by sender only
                read_by_all = random.random() > 0.3  # 70% chance fully read
                read_by = participants if read_by_all else [sender]
                
                message_data = {
                    "id": msg_id,
                    "senderId": sender,
                    "content": content,
                    "timestamp": SERVER_TIMESTAMP,
                    "readBy": read_by,
                    "deliveredTo": participants
                }
                
                conv_ref.collection("messages").document(msg_id).set(message_data)
                last_message = content
                total_messages += 1
            
            # Update conversation with last message
            if last_message:
                conv_ref.update({
                    "lastMessage": last_message,
                    "lastMessageTimestamp": SERVER_TIMESTAMP,
                    "updatedAt": SERVER_TIMESTAMP
                })
            
            conv_label = f"{conv_data.get('groupName', conv_id)}" if is_group else conv_id
        
        
    def create_test_presence(self):
        """Create test presence data."""
        
        if not self.test_users:
            return
        
        # Set first 2 users as online, rest as offline
        for i, user_id in enumerate(self.test_users):
            status = "online" if i < 2 else "offline"
            
            presence_data = {
                "status": status,
                "lastSeen": SERVER_TIMESTAMP,
                "typing": {}
            }
            
            self.db.collection("presence").document(user_id).set(presence_data)
        
        
    def seed_all(self, clear_first: bool = False, auto_confirm: bool = False):
        """
        Seed all collections with test data.
        
        Args:
            clear_first: If True, clear existing data before seeding
            auto_confirm: If True, skip confirmation prompt (for automated runs)
        """
        
        if clear_first:
            if not auto_confirm:
                confirm = input("\n⚠️  This will DELETE all existing data. Continue? (yes/no): ")
                if confirm.lower() != "yes":
                    return
            self.clear_collections()
        
        # Fetch existing Firebase Auth users
        existing_users = self.fetch_existing_users()
        
        if not existing_users:
            return
        
        # Ensure users exist in Firestore
        self.ensure_users_in_firestore(existing_users)
        
        # Seed in order (respecting dependencies)
        self.create_test_conversations()
        self.create_test_messages()
        self.create_test_presence()
        
        

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Seed Firestore database with test data from existing Firebase Auth users"
    )
    parser.add_argument(
        "--project-id",
        type=str,
        help="Firebase project ID (not needed if using emulator)"
    )
    parser.add_argument(
        "--emulator",
        action="store_true",
        help="Use local Firestore emulator (localhost:8080)"
    )
    parser.add_argument(
        "--clear",
        action="store_true",
        help="Clear existing data before seeding"
    )
    parser.add_argument(
        "--auto-confirm",
        action="store_true",
        help="Skip confirmation prompts (for automated deployment)"
    )
    
    args = parser.parse_args()
    
    # Validate arguments
    if not args.emulator and not args.project_id:
        parser.error("--project-id is required when not using --emulator")
    
    try:
        # Initialize seeder
        seeder = FirestoreSeeder(use_emulator=args.emulator)
        seeder.initialize_firestore(project_id=args.project_id)
        
        # Seed database
        seeder.seed_all(clear_first=args.clear, auto_confirm=args.auto_confirm)
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()

