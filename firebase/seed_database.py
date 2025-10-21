#!/usr/bin/env python3
"""
Firestore Database Seeding Script for Wutzup

This script initializes the Firestore database with test data for development and testing.

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

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    from google.cloud.firestore_v1 import SERVER_TIMESTAMP
except ImportError:
    print("Error: firebase-admin package not found.")
    print("Install with: pip install firebase-admin")
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
            print("🔧 Using Firestore Emulator at localhost:8080")
            
            if not firebase_admin._apps:
                firebase_admin.initialize_app()
        else:
            # Use production/staging
            if not project_id:
                raise ValueError("project_id required when not using emulator")
            
            print(f"🔥 Connecting to Firestore project: {project_id}")
            
            if not firebase_admin._apps:
                cred = credentials.ApplicationDefault()
                firebase_admin.initialize_app(cred, {
                    'projectId': project_id
                })
        
        self.db = firestore.client()
        print("✅ Firestore client initialized")
        
    def clear_collections(self):
        """Clear existing test data (use with caution!)."""
        print("\n⚠️  Clearing existing collections...")
        
        collections = ['users', 'conversations', 'presence', 'typing']
        
        for collection_name in collections:
            collection_ref = self.db.collection(collection_name)
            docs = collection_ref.stream()
            
            count = 0
            for doc in docs:
                doc.reference.delete()
                count += 1
            
            if count > 0:
                print(f"  Deleted {count} documents from {collection_name}")
        
        print("✅ Collections cleared")
        
    def create_test_users(self) -> List[str]:
        """
        Create test users.
        
        Returns:
            List of user IDs
        """
        print("\n👥 Creating test users...")
        
        test_users = [
            {
                "id": "user_alice",
                "email": "alice@example.com",
                "displayName": "Alice Smith",
                "profileImageUrl": "https://i.pravatar.cc/150?img=1",
                "createdAt": SERVER_TIMESTAMP
            },
            {
                "id": "user_bob",
                "email": "bob@example.com",
                "displayName": "Bob Jones",
                "profileImageUrl": "https://i.pravatar.cc/150?img=2",
                "createdAt": SERVER_TIMESTAMP
            },
            {
                "id": "user_charlie",
                "email": "charlie@example.com",
                "displayName": "Charlie Brown",
                "profileImageUrl": "https://i.pravatar.cc/150?img=3",
                "createdAt": SERVER_TIMESTAMP
            },
            {
                "id": "user_diana",
                "email": "diana@example.com",
                "displayName": "Diana Prince",
                "profileImageUrl": "https://i.pravatar.cc/150?img=4",
                "createdAt": SERVER_TIMESTAMP
            }
        ]
        
        user_ids = []
        for user_data in test_users:
            user_id = user_data["id"]
            self.db.collection("users").document(user_id).set(user_data)
            user_ids.append(user_id)
            print(f"  ✓ Created user: {user_data['displayName']} ({user_id})")
        
        self.test_users = user_ids
        print(f"✅ Created {len(user_ids)} test users")
        return user_ids
        
    def create_test_conversations(self) -> List[str]:
        """
        Create test conversations.
        
        Returns:
            List of conversation IDs
        """
        print("\n💬 Creating test conversations...")
        
        if len(self.test_users) < 2:
            print("⚠️  Need at least 2 users to create conversations")
            return []
        
        # One-on-one conversations
        conversations = [
            {
                "id": "conv_alice_bob",
                "participantIds": [self.test_users[0], self.test_users[1]],  # Alice & Bob
                "isGroup": False,
                "lastMessage": "Hey Bob! How's it going?",
                "lastMessageTimestamp": SERVER_TIMESTAMP,
                "createdAt": SERVER_TIMESTAMP,
                "updatedAt": SERVER_TIMESTAMP
            },
            {
                "id": "conv_alice_charlie",
                "participantIds": [self.test_users[0], self.test_users[2]],  # Alice & Charlie
                "isGroup": False,
                "createdAt": SERVER_TIMESTAMP,
                "updatedAt": SERVER_TIMESTAMP
            }
        ]
        
        # Group conversation (if we have 3+ users)
        if len(self.test_users) >= 3:
            conversations.append({
                "id": "conv_group_tech",
                "participantIds": [self.test_users[0], self.test_users[1], self.test_users[2]],
                "isGroup": True,
                "groupName": "Tech Team",
                "groupImageUrl": "https://i.pravatar.cc/150?img=10",
                "lastMessage": "See you all at the meeting!",
                "lastMessageTimestamp": SERVER_TIMESTAMP,
                "createdAt": SERVER_TIMESTAMP,
                "updatedAt": SERVER_TIMESTAMP
            })
        
        conversation_ids = []
        for conv_data in conversations:
            conv_id = conv_data["id"]
            self.db.collection("conversations").document(conv_id).set(conv_data)
            conversation_ids.append(conv_id)
            
            group_label = " (group)" if conv_data.get("isGroup") else ""
            print(f"  ✓ Created conversation: {conv_id}{group_label}")
        
        self.test_conversations = conversation_ids
        print(f"✅ Created {len(conversation_ids)} test conversations")
        return conversation_ids
        
    def create_test_messages(self):
        """Create test messages in conversations."""
        print("\n💌 Creating test messages...")
        
        if not self.test_conversations:
            print("⚠️  No conversations to add messages to")
            return
        
        # Messages for Alice & Bob conversation
        alice_bob_messages = [
            {
                "id": str(uuid.uuid4()),
                "senderId": self.test_users[0],  # Alice
                "content": "Hey Bob! How's it going?",
                "timestamp": SERVER_TIMESTAMP,
                "readBy": [self.test_users[0], self.test_users[1]],
                "deliveredTo": [self.test_users[0], self.test_users[1]]
            },
            {
                "id": str(uuid.uuid4()),
                "senderId": self.test_users[1],  # Bob
                "content": "Hi Alice! Pretty good, thanks! How about you?",
                "timestamp": SERVER_TIMESTAMP,
                "readBy": [self.test_users[0], self.test_users[1]],
                "deliveredTo": [self.test_users[0], self.test_users[1]]
            },
            {
                "id": str(uuid.uuid4()),
                "senderId": self.test_users[0],  # Alice
                "content": "Doing well! Want to grab coffee later?",
                "timestamp": SERVER_TIMESTAMP,
                "readBy": [self.test_users[0]],
                "deliveredTo": [self.test_users[0], self.test_users[1]]
            }
        ]
        
        conv_ref = self.db.collection("conversations").document(self.test_conversations[0])
        for msg in alice_bob_messages:
            conv_ref.collection("messages").document(msg["id"]).set(msg)
        
        print(f"  ✓ Added {len(alice_bob_messages)} messages to Alice & Bob conversation")
        
        # Messages for group conversation (if it exists)
        if len(self.test_conversations) >= 3:
            group_messages = [
                {
                    "id": str(uuid.uuid4()),
                    "senderId": self.test_users[0],  # Alice
                    "content": "Hey team! Quick reminder about tomorrow's meeting.",
                    "timestamp": SERVER_TIMESTAMP,
                    "readBy": [self.test_users[0]],
                    "deliveredTo": [self.test_users[0], self.test_users[1], self.test_users[2]]
                },
                {
                    "id": str(uuid.uuid4()),
                    "senderId": self.test_users[1],  # Bob
                    "content": "Thanks Alice! What time again?",
                    "timestamp": SERVER_TIMESTAMP,
                    "readBy": [self.test_users[0], self.test_users[1]],
                    "deliveredTo": [self.test_users[0], self.test_users[1], self.test_users[2]]
                },
                {
                    "id": str(uuid.uuid4()),
                    "senderId": self.test_users[0],  # Alice
                    "content": "10 AM in the main conference room",
                    "timestamp": SERVER_TIMESTAMP,
                    "readBy": [self.test_users[0]],
                    "deliveredTo": [self.test_users[0], self.test_users[1], self.test_users[2]]
                },
                {
                    "id": str(uuid.uuid4()),
                    "senderId": self.test_users[2],  # Charlie
                    "content": "Perfect, see you all there!",
                    "timestamp": SERVER_TIMESTAMP,
                    "readBy": [self.test_users[0], self.test_users[2]],
                    "deliveredTo": [self.test_users[0], self.test_users[1], self.test_users[2]]
                }
            ]
            
            conv_ref = self.db.collection("conversations").document(self.test_conversations[2])
            for msg in group_messages:
                conv_ref.collection("messages").document(msg["id"]).set(msg)
            
            print(f"  ✓ Added {len(group_messages)} messages to Tech Team group")
        
        print("✅ Test messages created")
        
    def create_test_presence(self):
        """Create test presence data."""
        print("\n👁️  Creating test presence data...")
        
        if not self.test_users:
            print("⚠️  No users to create presence for")
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
            print(f"  ✓ Set {user_id} presence: {status}")
        
        print("✅ Test presence data created")
        
    def seed_all(self, clear_first: bool = False):
        """
        Seed all collections with test data.
        
        Args:
            clear_first: If True, clear existing data before seeding
        """
        print("\n" + "="*60)
        print("🌱 Starting Firestore Database Seeding")
        print("="*60)
        
        if clear_first:
            confirm = input("\n⚠️  This will DELETE all existing data. Continue? (yes/no): ")
            if confirm.lower() != "yes":
                print("❌ Seeding cancelled")
                return
            self.clear_collections()
        
        # Seed in order (respecting dependencies)
        self.create_test_users()
        self.create_test_conversations()
        self.create_test_messages()
        self.create_test_presence()
        
        print("\n" + "="*60)
        print("✅ Database seeding completed successfully!")
        print("="*60)
        print("\n📊 Summary:")
        print(f"  - Users: {len(self.test_users)}")
        print(f"  - Conversations: {len(self.test_conversations)}")
        print(f"  - Messages: Created in conversations")
        print(f"  - Presence: {len(self.test_users)} users")
        print("\n💡 You can now test the app with this data!")
        

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Seed Firestore database with test data"
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
    
    args = parser.parse_args()
    
    # Validate arguments
    if not args.emulator and not args.project_id:
        parser.error("--project-id is required when not using --emulator")
    
    try:
        # Initialize seeder
        seeder = FirestoreSeeder(use_emulator=args.emulator)
        seeder.initialize_firestore(project_id=args.project_id)
        
        # Seed database
        seeder.seed_all(clear_first=args.clear)
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()

