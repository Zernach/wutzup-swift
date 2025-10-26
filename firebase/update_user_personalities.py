#!/usr/bin/env python3
"""
User Personality Update Script for Wutzup

This script updates all non-tutor users in the database by assigning them diverse personality values.
It ensures every regular user has a personality that helps the AI generate responses matching their communication style.

Usage:
    python update_user_personalities.py --project-id YOUR_PROJECT_ID
    python update_user_personalities.py --emulator  # Use local emulator
    python update_user_personalities.py --dry-run  # Preview changes without applying
"""

import argparse
import os
import sys
import random
from datetime import datetime
from typing import List, Dict, Any, Optional

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    from google.cloud.firestore_v1 import SERVER_TIMESTAMP
except ImportError:
    print("Error: Firebase Admin SDK not installed. Run: pip install firebase-admin")
    sys.exit(1)


# Diverse personality templates covering different communication styles and backgrounds
PERSONALITY_TEMPLATES = [
    # Professional & Business-oriented
    "Professional and goal-oriented communicator who values efficiency and clarity. Prefers direct, structured conversations and appreciates when others are punctual and well-prepared.",
    
    "Business-minded individual with a focus on networking and career development. Enjoys discussing industry trends, leadership, and professional growth opportunities.",
    
    "Entrepreneurial spirit who loves discussing startups, innovation, and creative problem-solving. Always looking for new opportunities and ways to improve processes.",
    
    # Creative & Artistic
    "Creative soul who expresses themselves through art, music, or writing. Enjoys deep conversations about inspiration, beauty, and the human experience.",
    
    "Artistic individual with a passion for design, photography, or visual arts. Appreciates aesthetic beauty and enjoys discussing creative projects and cultural events.",
    
    "Musician or music enthusiast who connects with others through rhythm and melody. Loves sharing playlists, discussing concerts, and discovering new artists.",
    
    # Social & Community-focused
    "Social butterfly who thrives on meaningful connections and community involvement. Enjoys organizing events, volunteering, and bringing people together.",
    
    "Community-minded individual who cares deeply about social causes and helping others. Passionate about making a positive impact in their local area.",
    
    "Family-oriented person who values relationships and traditions. Enjoys discussing family activities, parenting, and creating lasting memories.",
    
    # Intellectual & Academic
    "Intellectual who loves learning and discussing complex topics. Enjoys reading, research, and engaging in thoughtful debates about various subjects.",
    
    "Academic-minded individual with a passion for education and knowledge sharing. Enjoys teaching others and discussing scholarly topics.",
    
    "Curious learner who is always asking questions and exploring new ideas. Enjoys documentaries, podcasts, and discovering new perspectives.",
    
    # Adventurous & Active
    "Adventure seeker who loves outdoor activities, travel, and trying new experiences. Enjoys discussing hiking, camping, and exploring new places.",
    
    "Fitness enthusiast who is passionate about health, wellness, and staying active. Enjoys discussing workout routines, nutrition, and healthy living.",
    
    "Travel lover who enjoys sharing stories from different cultures and countries. Always planning the next adventure and loves discussing destinations.",
    
    # Tech & Innovation
    "Tech enthusiast who stays up-to-date with the latest gadgets and software. Enjoys discussing programming, AI, and digital innovation.",
    
    "Gaming enthusiast who loves discussing video games, esports, and gaming culture. Enjoys sharing strategies and discovering new games.",
    
    "Digital native who is comfortable with social media, online communities, and virtual interactions. Enjoys discussing internet culture and trends.",
    
    # Relaxed & Easygoing
    "Easygoing individual who prefers casual, stress-free conversations. Enjoys simple pleasures like good food, movies, and spending time with friends.",
    
    "Chill person who values work-life balance and doesn't take things too seriously. Enjoys humor, memes, and light-hearted conversations.",
    
    "Zen-like individual who practices mindfulness and enjoys discussing meditation, yoga, and spiritual growth.",
    
    # Food & Lifestyle
    "Foodie who loves cooking, dining out, and discussing culinary experiences. Enjoys sharing recipes and discovering new restaurants.",
    
    "Coffee connoisseur who appreciates quality beverages and café culture. Enjoys discussing brewing methods and finding the perfect cup.",
    
    "Wine enthusiast who enjoys discussing vintages, food pairings, and vineyard experiences. Appreciates the finer things in life.",
    
    # Sports & Competition
    "Sports fan who loves discussing games, players, and team strategies. Enjoys watching matches and participating in fantasy leagues.",
    
    "Competitive individual who enjoys challenges and strives for excellence. Enjoys discussing achievements and setting new goals.",
    
    "Team player who values collaboration and supporting others. Enjoys group activities and helping teammates succeed.",
    
    # Nature & Environment
    "Nature lover who is passionate about environmental conservation and outdoor activities. Enjoys discussing sustainability and wildlife.",
    
    "Gardening enthusiast who loves growing plants and discussing horticulture. Enjoys sharing tips about gardening and landscaping.",
    
    "Animal lover who is passionate about pets and wildlife. Enjoys discussing animal behavior and conservation efforts.",
    
    # Cultural & Global
    "Cultural enthusiast who loves learning about different traditions, languages, and customs. Enjoys discussing global perspectives and diversity.",
    
    "Language learner who is passionate about communication across cultures. Enjoys discussing linguistics and cultural exchange.",
    
    "Global citizen who values international connections and cross-cultural understanding. Enjoys discussing world events and cultural differences.",
    
    # Humor & Entertainment
    "Comedy lover who enjoys making others laugh and appreciates good humor. Enjoys sharing jokes, memes, and funny stories.",
    
    "Entertainment enthusiast who loves movies, TV shows, and pop culture. Enjoys discussing actors, directors, and entertainment industry news.",
    
    "Storyteller who enjoys sharing anecdotes and experiences in an engaging way. Enjoys listening to others' stories and creating memorable moments.",
    
    # Introspective & Thoughtful
    "Thoughtful individual who enjoys deep, meaningful conversations about life, philosophy, and personal growth. Values authenticity and introspection.",
    
    "Reflective person who takes time to process experiences and learn from them. Enjoys discussing personal development and life lessons.",
    
    "Empathetic listener who cares deeply about others' feelings and experiences. Enjoys providing support and understanding to friends and family."
]


class PersonalityUpdater:
    """Update user personalities in Firestore database."""
    
    def __init__(self, use_emulator: bool = False):
        """
        Initialize personality updater.
        
        Args:
            use_emulator: If True, connect to local emulator instead of production
        """
        self.use_emulator = use_emulator
        self.db = None
        self.updated_users = []
        
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
    
    def get_non_tutor_users(self) -> List[Dict[str, Any]]:
        """
        Fetch all users where isTutor is NOT true.
        
        Returns:
            List of user documents that need personality updates
        """
        print("🔍 Fetching non-tutor users from database...")
        
        try:
            # Query users where isTutor is not true (or doesn't exist)
            users_ref = self.db.collection("users")
            
            # Get all users first, then filter
            all_users = users_ref.stream()
            non_tutor_users = []
            
            for doc in all_users:
                user_data = doc.to_dict()
                user_id = doc.id
                
                # Check if user is NOT a tutor
                is_tutor = user_data.get("isTutor", False)
                if not is_tutor:
                    non_tutor_users.append({
                        "id": user_id,
                        "data": user_data,
                        "ref": doc.reference
                    })
            
            print(f"📊 Found {len(non_tutor_users)} non-tutor users")
            return non_tutor_users
            
        except Exception as e:
            print(f"❌ Error fetching users: {e}")
            return []
    
    def assign_personality(self, user_data: Dict[str, Any]) -> str:
        """
        Assign a diverse personality to a user.
        
        Args:
            user_data: User's existing data
            
        Returns:
            Selected personality string
        """
        # Get user's existing personality if any
        existing_personality = user_data.get("personality")
        
        # If user already has a personality, keep it (optional - you can change this behavior)
        if existing_personality and existing_personality.strip():
            return existing_personality
        
        # Randomly select a personality template
        selected_personality = random.choice(PERSONALITY_TEMPLATES)
        
        # Optionally customize based on user's existing data
        display_name = user_data.get("displayName", "")
        email = user_data.get("email", "")
        
        # Add a personal touch based on name or email if available
        if display_name:
            # Extract first name for personalization
            first_name = display_name.split()[0] if display_name else "there"
            personalized_personality = selected_personality.replace("individual", f"person named {first_name}")
            return personalized_personality
        
        return selected_personality
    
    def update_user_personalities(self, dry_run: bool = False) -> Dict[str, int]:
        """
        Update personalities for all non-tutor users.
        
        Args:
            dry_run: If True, preview changes without applying them
            
        Returns:
            Dictionary with update statistics
        """
        non_tutor_users = self.get_non_tutor_users()
        
        if not non_tutor_users:
            print("ℹ️  No non-tutor users found to update")
            return {"total": 0, "updated": 0, "skipped": 0}
        
        stats = {"total": len(non_tutor_users), "updated": 0, "skipped": 0}
        
        print(f"\n{'🔍 DRY RUN - ' if dry_run else '🔄 UPDATING '}Personalities for {len(non_tutor_users)} users...")
        print("=" * 80)
        
        for i, user_info in enumerate(non_tutor_users, 1):
            user_id = user_info["id"]
            user_data = user_info["data"]
            user_ref = user_info["ref"]
            
            display_name = user_data.get("displayName", "Unknown")
            email = user_data.get("email", "No email")
            existing_personality = user_data.get("personality")
            
            # Assign new personality
            new_personality = self.assign_personality(user_data)
            
            # Check if personality actually changed
            if existing_personality == new_personality:
                print(f"{i:2d}. ⏭️  {display_name} ({email}) - No change needed")
                stats["skipped"] += 1
                continue
            
            print(f"{i:2d}. {'🔍' if dry_run else '✅'} {display_name} ({email})")
            print(f"    {'Current:' if existing_personality else 'New:'} {existing_personality[:100] + '...' if existing_personality and len(existing_personality) > 100 else existing_personality or 'None'}")
            if existing_personality:
                print(f"    {'New:' if dry_run else 'Updated:'} {new_personality[:100] + '...' if len(new_personality) > 100 else new_personality}")
            print()
            
            if not dry_run:
                try:
                    # Update the user document
                    user_ref.update({
                        "personality": new_personality,
                        "updatedAt": SERVER_TIMESTAMP
                    })
                    
                    self.updated_users.append({
                        "id": user_id,
                        "displayName": display_name,
                        "email": email,
                        "oldPersonality": existing_personality,
                        "newPersonality": new_personality
                    })
                    
                    stats["updated"] += 1
                    
                except Exception as e:
                    print(f"    ❌ Error updating {display_name}: {e}")
                    stats["skipped"] += 1
        
        return stats
    
    def print_summary(self, stats: Dict[str, int], dry_run: bool = False):
        """Print update summary."""
        print("\n" + "=" * 80)
        print(f"📊 {'DRY RUN ' if dry_run else ''}SUMMARY")
        print("=" * 80)
        print(f"Total non-tutor users: {stats['total']}")
        print(f"{'Would update' if dry_run else 'Updated'}: {stats['updated']}")
        print(f"Skipped: {stats['skipped']}")
        
        if not dry_run and self.updated_users:
            print(f"\n✅ Successfully updated {len(self.updated_users)} users")
            
            # Show a few examples
            print("\n📝 Sample updates:")
            for i, user in enumerate(self.updated_users[:3], 1):
                print(f"{i}. {user['displayName']} ({user['email']})")
                print(f"   New personality: {user['newPersonality'][:150]}...")
                print()


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Update personalities for all non-tutor users in Wutzup database"
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
        "--dry-run",
        action="store_true",
        help="Preview changes without applying them"
    )
    parser.add_argument(
        "--auto-confirm",
        action="store_true",
        help="Skip confirmation prompts (for automated runs)"
    )
    
    args = parser.parse_args()
    
    # Validate arguments
    if not args.emulator and not args.project_id:
        parser.error("--project-id is required when not using --emulator")
    
    try:
        # Initialize updater
        updater = PersonalityUpdater(use_emulator=args.emulator)
        updater.initialize_firestore(project_id=args.project_id)
        
        # Confirm before proceeding (unless dry run or auto-confirm)
        if not args.dry_run and not args.auto_confirm:
            print("⚠️  This will update personalities for ALL non-tutor users.")
            print("💡 Use --dry-run to preview changes first.")
            confirm = input("\nContinue? (yes/no): ")
            if confirm.lower() != "yes":
                print("❌ Operation cancelled")
                return
        
        # Update personalities
        stats = updater.update_user_personalities(dry_run=args.dry_run)
        
        # Print summary
        updater.print_summary(stats, dry_run=args.dry_run)
        
        if args.dry_run:
            print("\n💡 To apply these changes, run the script without --dry-run")
        
    except Exception as e:
        import traceback
        print(f"❌ Error: {e}")
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
