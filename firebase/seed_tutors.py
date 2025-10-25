#!/usr/bin/env python3
"""
Firestore Tutor Seeding Script for Wutzup

This script initializes the Firestore database with diverse international AI tutors.
Each tutor has a unique personality, language expertise, and cultural background.

Usage:
    python seed_tutors.py --project-id YOUR_PROJECT_ID
    python seed_tutors.py --emulator  # Use local emulator
"""

import argparse
import os
import sys
from datetime import datetime
from typing import List, Dict, Any
import uuid

try:
    import firebase_admin
    from firebase_admin import credentials, firestore, auth
    from google.cloud.firestore_v1 import SERVER_TIMESTAMP
except ImportError:
    sys.exit(1)


# 20 diverse international tutors with authentic names and personalities
TUTORS_DATA = [
    {
        "displayName": "María García",
        "email": "maria.garcia@wutzup-tutor.ai",
        "personality": "Warm and encouraging Spanish tutor from Madrid with 15 years of teaching experience. Loves flamenco music and Mediterranean cuisine. Patient with beginners and excels at explaining grammar through cultural context.",
        "primaryLanguageCode": "es",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=maria-garcia"
    },
    {
        "displayName": "François Dubois",
        "email": "francois.dubois@wutzup-tutor.ai",
        "personality": "Sophisticated French tutor from Paris with a passion for literature and cinema. Emphasizes proper pronunciation and cultural nuances. Friendly yet meticulous, believes learning should be elegant and enjoyable.",
        "primaryLanguageCode": "fr",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=francois-dubois"
    },
    {
        "displayName": "Søren Nielsen",
        "email": "soren.nielsen@wutzup-tutor.ai",
        "personality": "Cheerful Danish tutor from Copenhagen who makes language learning fun through humor and storytelling. Former radio host with excellent communication skills. Specializes in conversational Danish and Nordic culture.",
        "primaryLanguageCode": "da",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=soren-nielsen"
    },
    {
        "displayName": "Yuki Tanaka",
        "email": "yuki.tanaka@wutzup-tutor.ai",
        "personality": "Methodical and supportive Japanese tutor from Tokyo. Expert in teaching kanji through mnemonic devices. Passionate about anime, manga, and traditional tea ceremony. Makes complex concepts accessible through visual learning.",
        "primaryLanguageCode": "ja",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=yuki-tanaka"
    },
    {
        "displayName": "Anya Petrova",
        "email": "anya.petrova@wutzup-tutor.ai",
        "personality": "Dynamic Russian tutor from St. Petersburg with a background in linguistics. Enthusiastic about Russian literature and history. Uses immersive storytelling and makes challenging grammar feel manageable.",
        "primaryLanguageCode": "ru",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=anya-petrova"
    },
    {
        "displayName": "João Silva",
        "email": "joao.silva@wutzup-tutor.ai",
        "personality": "Energetic Brazilian Portuguese tutor from Rio de Janeiro. Former samba musician who incorporates music and rhythm into language learning. Specializes in colloquial expressions and regional variations.",
        "primaryLanguageCode": "pt",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=joao-silva"
    },
    {
        "displayName": "Amélie Lefèvre",
        "email": "amelie.lefevre@wutzup-tutor.ai",
        "personality": "Creative French-Canadian tutor from Québec City. Artist and food enthusiast who teaches through cultural immersion. Specializes in making French accessible through visual arts and culinary vocabulary.",
        "primaryLanguageCode": "fr",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=amelie-lefevre"
    },
    {
        "displayName": "Björn Andersson",
        "email": "bjorn.andersson@wutzup-tutor.ai",
        "personality": "Calm and structured Swedish tutor from Stockholm. Software engineer turned language teacher with a systematic approach. Excellent at breaking down complex grammar into logical patterns. Loves hiking and photography.",
        "primaryLanguageCode": "sv",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=bjorn-andersson"
    },
    {
        "displayName": "Mónica Rodríguez",
        "email": "monica.rodriguez@wutzup-tutor.ai",
        "personality": "Vibrant Argentine Spanish tutor from Buenos Aires. Former theater actress with expressive teaching style. Makes learning Spanish fun through role-play and dramatic readings. Expert in Latin American cultural differences.",
        "primaryLanguageCode": "es",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=monica-rodriguez"
    },
    {
        "displayName": "Łukasz Kowalski",
        "email": "lukasz.kowalski@wutzup-tutor.ai",
        "personality": "Patient and thorough Polish tutor from Warsaw. History teacher with deep knowledge of Slavic languages. Uses historical context to explain linguistic evolution. Known for making Polish grammar approachable for beginners.",
        "primaryLanguageCode": "pl",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=lukasz-kowalski"
    },
    {
        "displayName": "Mei Chen",
        "email": "mei.chen@wutzup-tutor.ai",
        "personality": "Gentle and encouraging Mandarin tutor from Beijing. Calligraphy artist who teaches Chinese through visual character analysis. Specializes in tones and pronunciation. Makes learning characters feel like an art form.",
        "primaryLanguageCode": "zh",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=mei-chen"
    },
    {
        "displayName": "Jürgen Müller",
        "email": "jurgen.muller@wutzup-tutor.ai",
        "personality": "Precise and friendly German tutor from Munich. Engineer with a passion for teaching through practical applications. Makes German grammar logical and systematic. Loves discussing technology, cars, and German efficiency.",
        "primaryLanguageCode": "de",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=jurgen-muller"
    },
    {
        "displayName": "Sofía Fernández",
        "email": "sofia.fernandez@wutzup-tutor.ai",
        "personality": "Passionate Mexican Spanish tutor from Guadalajara. Anthropologist who teaches language through cultural lens. Expert in indigenous influences on modern Spanish. Warm teaching style focused on real-world communication.",
        "primaryLanguageCode": "es",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=sofia-fernandez"
    },
    {
        "displayName": "Nikolaos Papadopoulos",
        "email": "nikolaos.papadopoulos@wutzup-tutor.ai",
        "personality": "Philosophical Greek tutor from Athens. Classicist who connects modern Greek to ancient roots. Makes learning Greek alphabet and grammar engaging through mythology and philosophy. Patient with complex linguistic concepts.",
        "primaryLanguageCode": "el",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=nikolaos-papadopoulos"
    },
    {
        "displayName": "Siobhán O'Brien",
        "email": "siobhan.obrien@wutzup-tutor.ai",
        "personality": "Enthusiastic Irish Gaelic tutor from Galway. Musician and storyteller who teaches through traditional songs and folklore. Makes the challenges of Irish pronunciation fun. Passionate about preserving Celtic language and culture.",
        "primaryLanguageCode": "ga",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=siobhan-obrien"
    },
    {
        "displayName": "Đỗ Minh Tuấn",
        "email": "do.minhtuan@wutzup-tutor.ai",
        "personality": "Patient Vietnamese tutor from Hanoi with a background in phonetics. Excels at teaching tonal distinctions through music. Incorporates Vietnamese culture, cuisine, and history into lessons. Makes complex tones feel natural.",
        "primaryLanguageCode": "vi",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=do-minhtuan"
    },
    {
        "displayName": "Çağlar Yılmaz",
        "email": "caglar.yilmaz@wutzup-tutor.ai",
        "personality": "Energetic Turkish tutor from Istanbul. Former tour guide with extensive cultural knowledge. Teaches Turkish through storytelling about Turkish history and traditions. Excellent at explaining vowel harmony through practical examples.",
        "primaryLanguageCode": "tr",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=caglar-yilmaz"
    },
    {
        "displayName": "Ingrid Jørgensen",
        "email": "ingrid.jorgensen@wutzup-tutor.ai",
        "personality": "Supportive Norwegian tutor from Bergen. Environmental scientist who loves outdoor activities. Teaches Norwegian through nature vocabulary and sustainability topics. Patient and adaptable to different learning styles.",
        "primaryLanguageCode": "no",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=ingrid-jorgensen"
    },
    {
        "displayName": "András Kovács",
        "email": "andras.kovacs@wutzup-tutor.ai",
        "personality": "Witty Hungarian tutor from Budapest. Former comedy writer who makes difficult Hungarian grammar entertaining. Uses humor and wordplay to teach agglutinative structures. Makes one of Europe's hardest languages approachable.",
        "primaryLanguageCode": "hu",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=andras-kovacs"
    },
    {
        "displayName": "Kateřina Nováková",
        "email": "katerina.novakova@wutzup-tutor.ai",
        "personality": "Thoughtful Czech tutor from Prague. Literature professor with a love for poetry and classical music. Teaches Czech through literary examples and cultural context. Patient with the seven cases and makes them memorable through stories.",
        "primaryLanguageCode": "cs",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=katerina-novakova"
    }
]


class TutorSeeder:
    """Seed Firestore database with AI language tutors."""
    
    def __init__(self, use_emulator: bool = False):
        """
        Initialize tutor seeder.
        
        Args:
            use_emulator: If True, connect to local emulator instead of production
        """
        self.use_emulator = use_emulator
        self.db = None
        self.created_tutors = []
        
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
    
    def create_auth_user(self, email: str, display_name: str) -> str:
        """
        Create a Firebase Auth user for a tutor.
        
        Args:
            email: Tutor's email address
            display_name: Tutor's display name
            
        Returns:
            User ID (UID) of created user
        """
        try:
            # Check if user already exists
            try:
                existing_user = auth.get_user_by_email(email)
                return existing_user.uid
            except auth.UserNotFoundError:
                pass
            
            # Create new user
            user = auth.create_user(
                email=email,
                email_verified=True,
                display_name=display_name,
                password=str(uuid.uuid4()),  # Random password (tutors login via service)
                disabled=False
            )
            return user.uid
            
        except Exception as e:
            # Generate a deterministic UID from email for Firestore-only mode
            import hashlib
            uid = "tutor_" + hashlib.md5(email.encode()).hexdigest()[:20]
            return uid
    
    def create_tutors(self, skip_auth: bool = False) -> List[str]:
        """
        Create tutor user documents in Firestore.
        
        Args:
            skip_auth: If True, skip Firebase Auth creation (Firestore only)
            
        Returns:
            List of created tutor user IDs
        """
        
        tutor_ids = []
        
        for tutor_data in TUTORS_DATA:
            display_name = tutor_data["displayName"]
            email = tutor_data["email"]
            
            # Create Firebase Auth user (or generate UID)
            if skip_auth:
                import hashlib
                user_id = "tutor_" + hashlib.md5(email.encode()).hexdigest()[:20]
            else:
                user_id = self.create_auth_user(email, display_name)
            
            # Create Firestore user document
            user_doc = {
                "id": user_id,
                "email": email,
                "displayName": display_name,
                "profileImageUrl": tutor_data["profileImageUrl"],
                "personality": tutor_data["personality"],
                "primaryLanguageCode": tutor_data["primaryLanguageCode"],
                "learningLanguageCode": tutor_data["learningLanguageCode"],
                "isTutor": True,  # Mark as tutor
                "createdAt": SERVER_TIMESTAMP,
                "lastSeen": SERVER_TIMESTAMP
            }
            
            # Save to Firestore
            self.db.collection("users").document(user_id).set(user_doc)
            tutor_ids.append(user_id)
            
            lang_code = tutor_data["primaryLanguageCode"].upper()
        
        self.created_tutors = tutor_ids
        return tutor_ids
    
    def create_tutor_presence(self):
        """Create presence documents for all tutors (all online)."""
        
        for tutor_id in self.created_tutors:
            presence_data = {
                "status": "online",  # Tutors are always online
                "lastSeen": SERVER_TIMESTAMP,
                "typing": {}
            }
            
            self.db.collection("presence").document(tutor_id).set(presence_data)
        
    
    def seed_tutors(self, skip_auth: bool = False):
        """
        Seed all tutors into the database.
        
        Args:
            skip_auth: If True, skip Firebase Auth creation (Firestore only)
        """
        
        # Create tutors
        self.create_tutors(skip_auth=skip_auth)
        
        # Set up presence
        self.create_tutor_presence()
        
        


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Seed Firestore database with diverse international language tutors"
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
        "--skip-auth",
        action="store_true",
        help="Skip Firebase Auth creation (Firestore documents only)"
    )
    
    args = parser.parse_args()
    
    # Validate arguments
    if not args.emulator and not args.project_id:
        parser.error("--project-id is required when not using --emulator")
    
    try:
        # Initialize seeder
        seeder = TutorSeeder(use_emulator=args.emulator)
        seeder.initialize_firestore(project_id=args.project_id)
        
        # Seed tutors
        seeder.seed_tutors(skip_auth=args.skip_auth)
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()

