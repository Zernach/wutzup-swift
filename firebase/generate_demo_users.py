#!/usr/bin/env python3
"""
Demo User Generation Script for Wutzup

This script creates three diverse international demo users with authentic names,
profile images, personalities, and dozens of sample conversations including
research features for demo purposes.

Usage:
    python generate_demo_users.py --project-id YOUR_PROJECT_ID
    python generate_demo_users.py --emulator  # Use local emulator
"""

import argparse
import os
import sys
from datetime import datetime, timedelta
from typing import List, Dict, Any, Tuple
import uuid
import random
import hashlib

try:
    import firebase_admin
    from firebase_admin import credentials, firestore, auth
    from google.cloud.firestore_v1 import SERVER_TIMESTAMP
except ImportError:
    print("❌ Firebase Admin SDK not installed. Run: pip install firebase-admin")
    sys.exit(1)


# Three diverse international demo users with authentic names and personalities
DEMO_USERS = [
    {
        "displayName": "Aisha Al-Zahra",
        "email": "aisha.alzahra@wutzup.archlife.org",
        "personality": "Warm and intelligent Arabic tutor from Dubai with a passion for Middle Eastern culture and literature. Fluent in Arabic, English, and French. Loves discussing poetry, calligraphy, and traditional music. Patient teacher who makes complex Arabic grammar accessible through cultural stories and modern examples.",
        "primaryLanguageCode": "ar",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=aisha-alzahra",
        "country": "UAE",
        "interests": ["Arabic literature", "calligraphy", "poetry", "Middle Eastern culture", "teaching"]
    },
    {
        "displayName": "Kenji Nakamura",
        "email": "kenji.nakamura@wutzup.archlife.org", 
        "personality": "Methodical and creative Japanese software engineer from Tokyo who loves anime, manga, and traditional tea ceremony. Expert in both modern technology and ancient traditions. Enthusiastic about sharing Japanese culture through language learning. Makes complex kanji memorable through visual storytelling and pop culture references.",
        "primaryLanguageCode": "ja",
        "learningLanguageCode": "en",
        "profileImageUrl": "https://i.pravatar.cc/150?u=kenji-nakamura",
        "country": "Japan",
        "interests": ["anime", "manga", "programming", "tea ceremony", "technology"]
    },
    {
        "displayName": "Isabella Santos",
        "email": "isabella.santos@wutzup.archlife.org",
        "personality": "Vibrant Brazilian marketing professional from São Paulo with a love for samba, capoeira, and Brazilian cuisine. Passionate about social causes and environmental sustainability. Enthusiastic communicator who brings energy and warmth to every conversation. Loves sharing Brazilian culture through music, dance, and food stories.",
        "primaryLanguageCode": "pt",
        "learningLanguageCode": "en", 
        "profileImageUrl": "https://i.pravatar.cc/150?u=isabella-santos",
        "country": "Brazil",
        "interests": ["samba", "capoeira", "Brazilian cuisine", "marketing", "sustainability"]
    }
]

# Sample conversation topics and messages (multilingual)
CONVERSATION_TOPICS = [
    {
        "topic": "Language Learning",
        "messages": [
            {"content": "I've been practicing Arabic calligraphy lately. The curves are so beautiful!", "language": "en"},
            {"content": "Can you help me understand the difference between formal and informal Arabic?", "language": "en"},
            {"content": "أحب كيف أن الخط العربي جميل جداً", "language": "ar"},  # "I love how Arabic calligraphy is so beautiful"
            {"content": "I love how Japanese has different levels of politeness. It's so nuanced!", "language": "en"},
            {"content": "日本語の敬語は本当に複雑ですね", "language": "ja"},  # "Japanese honorifics are really complex, aren't they?"
            {"content": "Portuguese pronunciation is tricky, but I'm getting better with practice.", "language": "en"},
            {"content": "A pronúncia do português é difícil, mas estou melhorando!", "language": "pt"},  # "Portuguese pronunciation is difficult, but I'm improving!"
            {"content": "What's your favorite way to learn new vocabulary?", "language": "en"},
            {"content": "أفضل طريقة لتعلم المفردات الجديدة", "language": "ar"},  # "The best way to learn new vocabulary"
            {"content": "I've been watching anime with Japanese subtitles - it's helping a lot!", "language": "en"},
            {"content": "アニメを見ながら日本語を勉強しています", "language": "ja"},  # "I'm studying Japanese while watching anime"
            {"content": "Do you have any tips for remembering kanji characters?", "language": "en"},
            {"content": "I'm trying to learn Brazilian Portuguese slang. Any recommendations?", "language": "en"},
            {"content": "Estou aprendendo gírias brasileiras. Alguma dica?", "language": "pt"},  # "I'm learning Brazilian slang. Any tips?"
            {"content": "The Arabic alphabet is so elegant. I could study it for hours!", "language": "en"},
            {"content": "What's the most challenging part of learning your native language?", "language": "en"}
        ]
    },
    {
        "topic": "Cultural Exchange",
        "messages": [
            {"content": "Tell me about traditional festivals in your country!", "language": "en"},
            {"content": "أخبرني عن المهرجانات التقليدية في بلدك!", "language": "ar"},  # "Tell me about traditional festivals in your country!"
            {"content": "I'd love to visit Dubai someday. What should I see first?", "language": "en"},
            {"content": "دبي مدينة رائعة! يجب أن تزور برج خليفة", "language": "ar"},  # "Dubai is a wonderful city! You should visit Burj Khalifa"
            {"content": "Japanese tea ceremony sounds so peaceful and meaningful.", "language": "en"},
            {"content": "茶道はとても美しい日本の伝統です", "language": "ja"},  # "Tea ceremony is a very beautiful Japanese tradition"
            {"content": "Brazilian music is incredible! I've been listening to bossa nova.", "language": "en"},
            {"content": "A música brasileira é incrível! Bossa nova é linda", "language": "pt"},  # "Brazilian music is incredible! Bossa nova is beautiful"
            {"content": "What's your favorite traditional dish from home?", "language": "en"},
            {"content": "Qual é o seu prato tradicional favorito?", "language": "pt"},  # "What's your favorite traditional dish?"
            {"content": "I'm fascinated by Middle Eastern architecture and design.", "language": "en"},
            {"content": "أنا مفتون بالعمارة والتصميم العربي", "language": "ar"},  # "I'm fascinated by Arabic architecture and design"
            {"content": "Do you celebrate any unique holidays in your culture?", "language": "en"},
            {"content": "I love how different cultures express themselves through art.", "language": "en"},
            {"content": "文化の違いは本当に興味深いですね", "language": "ja"},  # "Cultural differences are really interesting, aren't they?"
            {"content": "What's the most beautiful place you've visited?", "language": "en"},
            {"content": "Cultural diversity makes the world so much richer!", "language": "en"}
        ]
    },
    {
        "topic": "Technology & Innovation",
        "messages": [
            {"content": "How is AI changing language learning in your country?", "language": "en"},
            {"content": "الذكاء الاصطناعي يغير طريقة تعلم اللغات", "language": "ar"},  # "AI is changing how we learn languages"
            {"content": "I'm working on a new app for cultural exchange. What features would you want?", "language": "en"},
            {"content": "テクノロジーは世界の人々を繋げています", "language": "ja"},  # "Technology is connecting people around the world"
            {"content": "Technology makes it so easy to connect with people worldwide!", "language": "en"},
            {"content": "A tecnologia facilita muito a conexão entre pessoas!", "language": "pt"},  # "Technology makes it very easy to connect people!"
            {"content": "What's the tech scene like in Tokyo? It must be amazing!", "language": "en"},
            {"content": "I love how apps can help preserve traditional languages.", "language": "en"},
            {"content": "أحب كيف تساعد التطبيقات في الحفاظ على اللغات التقليدية", "language": "ar"},  # "I love how apps help preserve traditional languages"
            {"content": "Virtual reality for language learning sounds fascinating!", "language": "en"},
            {"content": "How do you think technology will change education?", "language": "en"},
            {"content": "I'm learning to code. Any advice for beginners?", "language": "en"},
            {"content": "プログラミングを学んでいます。初心者へのアドバイスはありますか？", "language": "ja"},  # "I'm learning programming. Do you have advice for beginners?"
            {"content": "The future of communication is so exciting!", "language": "en"},
            {"content": "Technology should bring people together, not divide them.", "language": "en"}
        ]
    },
    {
        "topic": "Travel & Adventure",
        "messages": [
            {"content": "Where's your dream travel destination?", "language": "en"},
            {"content": "أين هو وجهة السفر المفضلة لديك؟", "language": "ar"},  # "Where is your favorite travel destination?"
            {"content": "I'm planning a trip to Japan next year. Any must-see places?", "language": "en"},
            {"content": "来年日本に旅行する予定です。おすすめの場所はありますか？", "language": "ja"},  # "I'm planning to travel to Japan next year. Do you have any recommended places?"
            {"content": "Brazilian beaches look absolutely stunning!", "language": "en"},
            {"content": "As praias brasileiras são lindas!", "language": "pt"},  # "Brazilian beaches are beautiful!"
            {"content": "I'd love to experience the desert in the Middle East.", "language": "en"},
            {"content": "What's the most adventurous thing you've ever done?", "language": "en"},
            {"content": "Travel opens your mind to so many new perspectives!", "language": "en"},
            {"content": "السياحة تفتح العقل على وجهات نظر جديدة", "language": "ar"},  # "Travel opens the mind to new perspectives"
            {"content": "I'm saving up for a world tour. Any tips?", "language": "en"},
            {"content": "What's your favorite travel memory?", "language": "en"},
            {"content": "I love meeting locals when I travel - they know the best spots!", "language": "en"},
            {"content": "Traveling solo taught me so much about myself.", "language": "en"}
        ]
    },
    {
        "topic": "Food & Cuisine",
        "messages": [
            {"content": "I'm learning to cook Arabic dishes. Any recipe recommendations?", "language": "en"},
            {"content": "أتعلم طبخ الأطباق العربية. أي وصفات تنصح بها؟", "language": "ar"},  # "I'm learning to cook Arabic dishes. What recipes do you recommend?"
            {"content": "Japanese cuisine is so beautifully presented!", "language": "en"},
            {"content": "日本料理はとても美しく盛り付けられています", "language": "ja"},  # "Japanese cuisine is very beautifully presented"
            {"content": "Brazilian food is so diverse and flavorful!", "language": "en"},
            {"content": "A comida brasileira é muito diversa e saborosa!", "language": "pt"},  # "Brazilian food is very diverse and flavorful!"
            {"content": "What's your comfort food from home?", "language": "en"},
            {"content": "I love trying new spices and flavors from different cultures.", "language": "en"},
            {"content": "Cooking brings people together across all cultures!", "language": "en"},
            {"content": "الطبخ يجمع الناس من جميع الثقافات", "language": "ar"},  # "Cooking brings people together from all cultures"
            {"content": "What's the most unusual food you've ever tried?", "language": "en"},
            {"content": "I'm hosting an international dinner party. Any suggestions?", "language": "en"},
            {"content": "Food tells such interesting stories about culture!", "language": "en"},
            {"content": "I love how every culture has its own unique flavors.", "language": "en"}
        ]
    },
    {
        "topic": "Music & Arts",
        "messages": [
            {"content": "Arabic music has such beautiful melodies!", "language": "en"},
            {"content": "الموسيقى العربية لها ألحان جميلة جداً", "language": "ar"},  # "Arabic music has very beautiful melodies"
            {"content": "I'm learning to play traditional Japanese instruments.", "language": "en"},
            {"content": "日本の伝統楽器を学んでいます", "language": "ja"},  # "I'm learning traditional Japanese instruments"
            {"content": "Brazilian music makes me want to dance!", "language": "en"},
            {"content": "A música brasileira me faz querer dançar!", "language": "pt"},  # "Brazilian music makes me want to dance!"
            {"content": "What's your favorite type of music?", "language": "en"},
            {"content": "Art transcends language barriers beautifully.", "language": "en"},
            {"content": "I love how music connects people across cultures.", "language": "en"},
            {"content": "أحب كيف تربط الموسيقى الناس عبر الثقافات", "language": "ar"},  # "I love how music connects people across cultures"
            {"content": "What's the most moving piece of art you've seen?", "language": "en"},
            {"content": "Traditional dances are so expressive and meaningful.", "language": "en"},
            {"content": "Music is truly a universal language!", "language": "en"},
            {"content": "I'm fascinated by how different cultures express emotion through art.", "language": "en"}
        ]
    }
]

# Research topics and results for demo
RESEARCH_TOPICS = [
    {
        "prompt": "What are the latest trends in language learning technology?",
        "result": """🔍 Research Results: What are the latest trends in language learning technology?

**Key Findings:**

1. **AI-Powered Personalization**: Advanced algorithms now create customized learning paths based on individual learning styles, pace, and interests. This includes adaptive vocabulary selection and grammar progression.

2. **Immersive VR/AR Experiences**: Virtual reality is revolutionizing language learning by placing users in realistic scenarios like ordering food in a Parisian café or navigating Tokyo's streets, making learning more engaging and practical.

3. **Real-Time Speech Recognition**: Advanced speech recognition technology provides instant pronunciation feedback, helping learners improve their accent and fluency in real-time.

4. **Gamification & Microlearning**: Apps are incorporating game-like elements with bite-sized lessons that fit into busy schedules, increasing retention rates by up to 40%.

5. **Cultural Context Integration**: Modern platforms emphasize cultural understanding alongside language skills, teaching idioms, gestures, and social norms.

6. **Community-Driven Learning**: Peer-to-peer learning platforms connect native speakers with learners for authentic conversation practice.

**Impact**: These technologies are making language learning 3x faster and more accessible to global audiences, with completion rates increasing significantly."""
    },
    {
        "prompt": "How does cultural background influence communication styles?",
        "result": """🔍 Research Results: How does cultural background influence communication styles?

**Cultural Communication Patterns:**

1. **High-Context vs Low-Context Cultures**:
   - High-context (Japan, Arab countries): Relies heavily on implicit understanding, non-verbal cues, and shared cultural knowledge
   - Low-context (US, Germany): Prefers explicit, direct communication with clear verbal explanations

2. **Individualistic vs Collectivistic Approaches**:
   - Individualistic cultures emphasize personal achievement and direct expression
   - Collectivistic cultures prioritize group harmony and indirect communication to avoid conflict

3. **Power Distance Variations**:
   - High power distance cultures (Brazil, UAE) show respect through formal language and hierarchical communication
   - Low power distance cultures encourage informal, egalitarian communication styles

4. **Time Orientation**:
   - Monochronic cultures (Germany, Japan) value punctuality and sequential task completion
   - Polychronic cultures (Brazil, Middle East) are more flexible with time and multitask-oriented

5. **Emotional Expression**:
   - Some cultures encourage open emotional expression (Brazil, Italy)
   - Others value emotional restraint and subtlety (Japan, Nordic countries)

**Practical Implications**: Understanding these differences is crucial for effective cross-cultural communication and can prevent misunderstandings in international business and personal relationships."""
    },
    {
        "prompt": "What are the benefits of multilingualism for cognitive development?",
        "result": """🔍 Research Results: What are the benefits of multilingualism for cognitive development?

**Cognitive Benefits of Multilingualism:**

1. **Enhanced Executive Function**: Bilingual individuals show superior performance in tasks requiring attention control, working memory, and cognitive flexibility. This "bilingual advantage" persists throughout life.

2. **Delayed Cognitive Decline**: Studies show that multilingualism can delay the onset of Alzheimer's disease and dementia by up to 4-5 years, providing significant cognitive protection.

3. **Improved Problem-Solving Skills**: Multilingual individuals demonstrate enhanced creative thinking and ability to approach problems from multiple perspectives, leading to more innovative solutions.

4. **Better Metalinguistic Awareness**: Understanding multiple languages improves awareness of language structure, making it easier to learn additional languages and understand complex linguistic concepts.

5. **Enhanced Memory**: The constant mental switching between languages strengthens memory systems and improves both short-term and long-term memory capacity.

6. **Increased Cultural Sensitivity**: Multilingual individuals typically show greater empathy, cultural awareness, and ability to understand different worldviews.

7. **Academic Performance**: Children learning multiple languages often outperform monolingual peers in standardized tests, particularly in mathematics and reading comprehension.

**Long-term Impact**: Multilingualism provides lifelong cognitive benefits and is increasingly recognized as a key factor in maintaining brain health and intellectual vitality."""
    }
]

# Group conversation topics
GROUP_CONVERSATIONS = [
    {
        "name": "Global Language Exchange",
        "description": "International language learning community",
        "messages": [
            {"content": "Welcome everyone! Let's share our language learning journeys! 🌍", "language": "en"},
            {"content": "مرحباً بالجميع! دعونا نتشارك رحلاتنا في تعلم اللغات! 🌍", "language": "ar"},  # "Welcome everyone! Let's share our language learning journeys! 🌍"
            {"content": "I'm so excited to learn from all of you!", "language": "en"},
            {"content": "このグループで学べるのがとても楽しみです！", "language": "ja"},  # "I'm very excited to learn in this group!"
            {"content": "This is such a diverse group - we can learn so much from each other!", "language": "en"},
            {"content": "Does anyone want to practice speaking together?", "language": "en"},
            {"content": "I love how technology brings us all together!", "language": "en"},
            {"content": "A tecnologia nos conecta de forma incrível!", "language": "pt"},  # "Technology connects us in an incredible way!"
            {"content": "What's the most interesting thing you've learned about another culture?", "language": "en"},
            {"content": "Let's organize a virtual cultural exchange event!", "language": "en"},
            {"content": "I'm grateful to be part of this amazing community!", "language": "en"},
            {"content": "Language learning is so much more fun with friends!", "language": "en"},
            {"content": "Thank you all for sharing your experiences! 🙏", "language": "en"}
        ]
    },
    {
        "name": "Cultural Explorers",
        "description": "Sharing cultural experiences and traditions",
        "messages": [
            {"content": "Tell us about a unique tradition from your country!", "language": "en"},
            {"content": "أخبرونا عن تقليد فريد من بلدكم!", "language": "ar"},  # "Tell us about a unique tradition from your country!"
            {"content": "I'm fascinated by how different cultures celebrate holidays!", "language": "en"},
            {"content": "Food is such a great way to learn about culture!", "language": "en"},
            {"content": "A comida é uma ótima forma de aprender sobre cultura!", "language": "pt"},  # "Food is a great way to learn about culture!"
            {"content": "What's your favorite cultural festival?", "language": "en"},
            {"content": "I love learning about traditional music and dance!", "language": "en"},
            {"content": "Cultural exchange makes the world more beautiful!", "language": "en"},
            {"content": "文化の交換は世界をより美しくします", "language": "ja"},  # "Cultural exchange makes the world more beautiful"
            {"content": "Let's share photos of our cultural celebrations!", "language": "en"},
            {"content": "I'm planning to visit all your countries someday!", "language": "en"},
            {"content": "Every culture has such beautiful stories to tell!", "language": "en"},
            {"content": "This group is like a window to the world! 🌎", "language": "en"}
        ]
    },
    {
        "name": "Tech Innovators",
        "description": "Discussing technology and innovation",
        "messages": [
            {"content": "How is technology changing education in your country?", "language": "en"},
            {"content": "كيف تغير التكنولوجيا التعليم في بلدكم؟", "language": "ar"},  # "How is technology changing education in your country?"
            {"content": "I'm working on an app for language learning!", "language": "en"},
            {"content": "AI is revolutionizing how we learn languages!", "language": "en"},
            {"content": "What's the most innovative tech you've seen recently?", "language": "en"},
            {"content": "Technology should connect people, not divide them!", "language": "en"},
            {"content": "I love how apps make learning accessible to everyone!", "language": "en"},
            {"content": "アプリが学習を誰にでもアクセス可能にしているのが素晴らしい！", "language": "ja"},  # "It's wonderful how apps make learning accessible to everyone!"
            {"content": "The future of communication is so exciting!", "language": "en"},
            {"content": "Let's collaborate on a tech project together!", "language": "en"},
            {"content": "Innovation happens when diverse minds come together!", "language": "en"},
            {"content": "A inovação acontece quando mentes diversas se unem!", "language": "pt"},  # "Innovation happens when diverse minds come together!"
            {"content": "Technology is breaking down barriers every day! 🚀", "language": "en"}
        ]
    }
]


class DemoUserGenerator:
    """Generate demo users with diverse international backgrounds and sample conversations."""
    
    def __init__(self, use_emulator: bool = False):
        """
        Initialize demo user generator.
        
        Args:
            use_emulator: If True, connect to local emulator instead of production
        """
        self.use_emulator = use_emulator
        self.db = None
        self.created_users = []
        self.created_conversations = []
        self.existing_users = []
        
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
    
    def fetch_existing_users(self) -> List[Dict[str, Any]]:
        """Fetch existing users from Firestore to create conversations with."""
        
        try:
            users_ref = self.db.collection("users")
            docs = users_ref.stream()
            
            users = []
            for doc in docs:
                user_data = doc.to_dict()
                if not user_data.get("isTutor", False):  # Exclude tutors
                    users.append({
                        "id": doc.id,
                        "displayName": user_data.get("displayName", "User"),
                        "email": user_data.get("email", "")
                    })
            
            self.existing_users = users
            print(f"📋 Found {len(users)} existing users for conversations")
            return users
            
        except Exception as e:
            print(f"⚠️  Could not fetch existing users: {e}")
            return []
    
    def create_demo_users(self) -> List[str]:
        """Create demo users in Firebase Auth and Firestore."""
        
        user_ids = []
        
        for user_data in DEMO_USERS:
            display_name = user_data["displayName"]
            email = user_data["email"]
            
            # Create Firebase Auth user
            try:
                # Check if user already exists
                try:
                    existing_user = auth.get_user_by_email(email)
                    user_id = existing_user.uid
                    print(f"👤 User {display_name} already exists")
                except auth.UserNotFoundError:
                    # Create new user
                    user = auth.create_user(
                        email=email,
                        email_verified=True,
                        display_name=display_name,
                        password="password",  # Demo password for easy login
                        disabled=False
                    )
                    user_id = user.uid
                    print(f"✅ Created user: {display_name}")
                
                # Create Firestore user document
                firestore_user = {
                    "id": user_id,
                    "email": email,
                    "displayName": display_name,
                    "profileImageUrl": user_data["profileImageUrl"],
                    "personality": user_data["personality"],
                    "primaryLanguageCode": user_data["primaryLanguageCode"],
                    "learningLanguageCode": user_data["learningLanguageCode"],
                    "isTutor": False,
                    "createdAt": SERVER_TIMESTAMP,
                    "lastSeen": SERVER_TIMESTAMP
                }
                
                self.db.collection("users").document(user_id).set(firestore_user)
                user_ids.append(user_id)
                
            except Exception as e:
                print(f"❌ Error creating user {display_name}: {e}")
                # Generate deterministic UID for Firestore-only mode
                user_id = "demo_" + hashlib.md5(email.encode()).hexdigest()[:20]
                user_ids.append(user_id)
        
        self.created_users = user_ids
        return user_ids
    
    def create_demo_conversations(self) -> List[str]:
        """Create diverse conversations between demo users and existing users."""
        
        conversation_ids = []
        all_users = self.created_users + [u["id"] for u in self.existing_users]
        
        if len(all_users) < 2:
            print("⚠️  Need at least 2 users to create conversations")
            return []
        
        # Create one-on-one conversations between demo users and existing users
        demo_user_names = {}
        for user_id in self.created_users:
            user_doc = self.db.collection("users").document(user_id).get()
            if user_doc.exists:
                demo_user_names[user_id] = user_doc.to_dict().get("displayName", "User")
        
        # Create conversations between each demo user and existing users
        conv_count = 0
        for demo_user_id in self.created_users:
            for existing_user in self.existing_users[:3]:  # Limit to 3 conversations per demo user
                existing_user_id = existing_user["id"]
                
                conv_id = f"demo_conv_{conv_count}"
                conv_count += 1
                
                participant_names = {
                    demo_user_id: demo_user_names.get(demo_user_id, "Demo User"),
                    existing_user_id: existing_user["displayName"]
                }
                
                conversation_data = {
                    "id": conv_id,
                    "participantIds": [demo_user_id, existing_user_id],
                    "participantNames": participant_names,
                    "isGroup": False,
                    "createdAt": SERVER_TIMESTAMP,
                    "updatedAt": SERVER_TIMESTAMP,
                    "unreadCount": 0
                }
                
                self.db.collection("conversations").document(conv_id).set(conversation_data)
                conversation_ids.append(conv_id)
                
                print(f"💬 Created conversation: {demo_user_names.get(demo_user_id)} ↔ {existing_user['displayName']}")
        
        # Create conversations between demo users
        if len(self.created_users) >= 2:
            for i in range(len(self.created_users)):
                for j in range(i + 1, len(self.created_users)):
                    conv_id = f"demo_conv_{conv_count}"
                    conv_count += 1
                    
                    user1_id = self.created_users[i]
                    user2_id = self.created_users[j]
                    
                    participant_names = {
                        user1_id: demo_user_names.get(user1_id, "Demo User"),
                        user2_id: demo_user_names.get(user2_id, "Demo User")
                    }
                    
                    conversation_data = {
                        "id": conv_id,
                        "participantIds": [user1_id, user2_id],
                        "participantNames": participant_names,
                        "isGroup": False,
                        "createdAt": SERVER_TIMESTAMP,
                        "updatedAt": SERVER_TIMESTAMP,
                        "unreadCount": 0
                    }
                    
                    self.db.collection("conversations").document(conv_id).set(conversation_data)
                    conversation_ids.append(conv_id)
                    
                    print(f"💬 Created conversation: {demo_user_names.get(user1_id)} ↔ {demo_user_names.get(user2_id)}")
        
        # Create group conversations
        if len(all_users) >= 3:
            for group_data in GROUP_CONVERSATIONS:
                conv_id = f"demo_group_{conv_count}"
                conv_count += 1
                
                # Select 3-5 random participants including demo users
                num_participants = min(random.randint(3, 5), len(all_users))
                participants = random.sample(all_users, num_participants)
                
                participant_names = {}
                for user_id in participants:
                    if user_id in demo_user_names:
                        participant_names[user_id] = demo_user_names[user_id]
                    else:
                        # Get name from existing users
                        for existing_user in self.existing_users:
                            if existing_user["id"] == user_id:
                                participant_names[user_id] = existing_user["displayName"]
                                break
                
                conversation_data = {
                    "id": conv_id,
                    "participantIds": participants,
                    "participantNames": participant_names,
                    "isGroup": True,
                    "groupName": group_data["name"],
                    "groupImageUrl": f"https://i.pravatar.cc/150?img={20 + conv_count}",
                    "createdAt": SERVER_TIMESTAMP,
                    "updatedAt": SERVER_TIMESTAMP,
                    "unreadCount": 0
                }
                
                self.db.collection("conversations").document(conv_id).set(conversation_data)
                conversation_ids.append(conv_id)
                
                print(f"👥 Created group: {group_data['name']}")
        
        self.created_conversations = conversation_ids
        return conversation_ids
    
    def create_sample_messages(self):
        """Create diverse sample messages including research results."""
        
        if not self.created_conversations:
            return
        
        total_messages = 0
        
        for conv_id in self.created_conversations:
            conv_ref = self.db.collection("conversations").document(conv_id)
            conv_doc = conv_ref.get()
            
            if not conv_doc.exists:
                continue
            
            conv_data = conv_doc.to_dict()
            participants = conv_data.get("participantIds", [])
            is_group = conv_data.get("isGroup", False)
            
            # Select conversation topic
            topic = random.choice(CONVERSATION_TOPICS)
            messages_to_add = random.sample(topic["messages"], min(random.randint(5, 10), len(topic["messages"])))
            
            # Add research message to some conversations
            if random.random() < 0.3:  # 30% chance of research message
                research_topic = random.choice(RESEARCH_TOPICS)
                messages_to_add.append({"content": research_topic["result"], "language": "en"})
            
            last_message = ""
            for i, message_obj in enumerate(messages_to_add):
                sender = random.choice(participants)
                msg_id = str(uuid.uuid4())
                
                # Handle both old string format and new dict format
                if isinstance(message_obj, dict):
                    content = message_obj["content"]
                    language = message_obj["language"]
                else:
                    content = message_obj
                    language = "en"  # Default to English for old format
                
                # Random read status
                read_by_all = random.random() > 0.2  # 80% chance fully read
                read_by = participants if read_by_all else [sender]
                
                # Add some time variation between messages
                timestamp_offset = timedelta(minutes=random.randint(1, 60))
                message_timestamp = datetime.now() - timedelta(days=random.randint(1, 30)) - timestamp_offset
                
                message_data = {
                    "id": msg_id,
                    "senderId": sender,
                    "content": content,
                    "timestamp": message_timestamp,
                    "language": language,
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
            
            conv_name = conv_data.get("groupName", conv_id)
            print(f"📝 Added {len(messages_to_add)} messages to {conv_name}")
        
        print(f"📊 Total messages created: {total_messages}")
    
    def create_demo_presence(self):
        """Create presence data for demo users."""
        
        for user_id in self.created_users:
            presence_data = {
                "status": "online",
                "lastSeen": SERVER_TIMESTAMP,
                "typing": {}
            }
            
            self.db.collection("presence").document(user_id).set(presence_data)
        
        print(f"🟢 Set presence for {len(self.created_users)} demo users")
    
    def generate_demo_data(self):
        """Generate all demo data."""
        
        print("🚀 Starting demo user generation...")
        
        # Fetch existing users for conversations
        self.fetch_existing_users()
        
        # Create demo users
        self.create_demo_users()
        
        # Create conversations
        self.create_demo_conversations()
        
        # Create sample messages
        self.create_sample_messages()
        
        # Set presence
        self.create_demo_presence()
        
        print("\n✅ Demo user generation complete!")
        print(f"👥 Created {len(self.created_users)} demo users")
        print(f"💬 Created {len(self.created_conversations)} conversations")
        print(f"📝 Added sample messages with research features")
        
        print("\n🎯 Demo Users Created:")
        for i, user_data in enumerate(DEMO_USERS, 1):
            print(f"  {i}. {user_data['displayName']} ({user_data['country']}) - {user_data['email']}")
        
        print("\n🔑 Login Credentials:")
        print("Note: Demo users have random passwords. Use Firebase Auth admin to reset passwords for demo purposes.")


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Generate demo users with diverse international backgrounds and sample conversations"
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
    
    args = parser.parse_args()
    
    # Validate arguments
    if not args.emulator and not args.project_id:
        parser.error("--project-id is required when not using --emulator")
    
    try:
        # Initialize generator
        generator = DemoUserGenerator(use_emulator=args.emulator)
        generator.initialize_firestore(project_id=args.project_id)
        
        # Generate demo data
        generator.generate_demo_data()
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
