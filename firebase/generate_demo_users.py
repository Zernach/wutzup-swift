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
            {"content": "أحب كيف أن الخط العربي جميل جداً", "language": "ar"},  # "I love how Arabic calligraphy is so beautiful"
            {"content": "Estoy aprendiendo español. ¿Alguien puede ayudarme?", "language": "es"},  # "I'm learning Spanish. Can anyone help me?"
            {"content": "J'apprends le français depuis six mois maintenant", "language": "fr"},  # "I've been learning French for six months now"
            {"content": "Can you help me understand the difference between formal and informal Arabic?", "language": "en"},
            {"content": "日本語の敬語は本当に複雑ですね", "language": "ja"},  # "Japanese honorifics are really complex, aren't they?"
            {"content": "Deutsch lernen ist sehr interessant", "language": "de"},  # "Learning German is very interesting"
            {"content": "A pronúncia do português é difícil, mas estou melhorando!", "language": "pt"},  # "Portuguese pronunciation is difficult, but I'm improving!"
            {"content": "我学习中文已经有两年了", "language": "zh"},  # "I've been learning Chinese for two years"
            {"content": "أفضل طريقة لتعلم المفردات الجديدة", "language": "ar"},  # "The best way to learn new vocabulary"
            {"content": "I've been watching anime with Japanese subtitles - it's helping a lot!", "language": "en"},
            {"content": "Apprendo l'italiano ascoltando musica italiana", "language": "it"},  # "I'm learning Italian by listening to Italian music"
            {"content": "Korea dilini öğrenmek istiyorum", "language": "tr"},  # "I want to learn Korean"
            {"content": "Estou aprendendo gírias brasileiras. Alguma dica?", "language": "pt"},  # "I'm learning Brazilian slang. Any tips?"
            {"content": "私はフランス語を学んでいます。あなたは私を助けることができますか？", "language": "ja"},  # "I'm learning French. Can you help me?"
            {"content": "What's the most challenging part of learning your native language?", "language": "en"},
            {"content": "Estoy practicando todos los días para mejorar", "language": "es"}  # "I'm practicing every day to improve"
        ]
    },
    {
        "topic": "Cultural Exchange",
        "messages": [
            {"content": "أخبرني عن المهرجانات التقليدية في بلدك!", "language": "ar"},  # "Tell me about traditional festivals in your country!"
            {"content": "¿Puedes contarme sobre tu cultura?", "language": "es"},  # "Can you tell me about your culture?"
            {"content": "J'aimerais visiter la France et découvrir sa culture", "language": "fr"},  # "I'd like to visit France and discover its culture"
            {"content": "I'd love to visit Dubai someday. What should I see first?", "language": "en"},
            {"content": "دبي مدينة رائعة! يجب أن تزور برج خليفة", "language": "ar"},  # "Dubai is a wonderful city! You should visit Burj Khalifa"
            {"content": "茶道はとても美しい日本の伝統です", "language": "ja"},  # "Tea ceremony is a very beautiful Japanese tradition"
            {"content": "A música brasileira é incrível! Bossa nova é linda", "language": "pt"},  # "Brazilian music is incredible! Bossa nova is beautiful"
            {"content": "J'adore la cuisine italienne. C'est délicieux!", "language": "fr"},  # "I love Italian cuisine. It's delicious!"
            {"content": "Was ist dein Lieblingsfestival in Deutschland?", "language": "de"},  # "What's your favorite festival in Germany?"
            {"content": "Qual é o seu prato tradicional favorito?", "language": "pt"},  # "What's your favorite traditional dish?"
            {"content": "أنا مفتون بالعمارة والتصميم العربي", "language": "ar"},  # "I'm fascinated by Arabic architecture and design"
            {"content": "Je suis fasciné par les différentes cultures", "language": "fr"},  # "I'm fascinated by different cultures"
            {"content": "文化の違いは本当に興味深いですね", "language": "ja"},  # "Cultural differences are really interesting, aren't they?"
            {"content": "Las diferencias culturales son fascinantes", "language": "es"},  # "Cultural differences are fascinating"
            {"content": "What's the most beautiful place you've visited?", "language": "en"},
            {"content": "Cultural diversity makes the world so much richer!", "language": "en"}
        ]
    },
    {
        "topic": "Technology & Innovation",
        "messages": [
            {"content": "الذكاء الاصطناعي يغير طريقة تعلم اللغات", "language": "ar"},  # "AI is changing how we learn languages"
            {"content": "La inteligencia artificial está cambiando todo", "language": "es"},  # "Artificial intelligence is changing everything"
            {"content": "Comment la technologie transforme-t-elle votre pays?", "language": "fr"},  # "How is technology transforming your country?"
            {"content": "How is AI changing language learning in your country?", "language": "en"},
            {"content": "テクノロジーは世界の人々を繋げています", "language": "ja"},  # "Technology is connecting people around the world"
            {"content": "A tecnologia facilita muito a conexão entre pessoas!", "language": "pt"},  # "Technology makes it very easy to connect people!"
            {"content": "Die Technologie verbindet die Welt", "language": "de"},  # "Technology connects the world"
            {"content": "La tecnologia sta cambiando il mondo", "language": "it"},  # "Technology is changing the world"
            {"content": "أحب كيف تساعد التطبيقات في الحفاظ على اللغات التقليدية", "language": "ar"},  # "I love how apps help preserve traditional languages"
            {"content": "La realidad virtual es el futuro", "language": "es"},  # "Virtual reality is the future"
            {"content": "What's the tech scene like in Tokyo? It must be amazing!", "language": "en"},
            {"content": "プログラミングを学んでいます。初心者へのアドバイスはありますか？", "language": "ja"},  # "I'm learning programming. Do you have advice for beginners?"
            {"content": "Estou aprendendo a programar. Alguma dica?", "language": "pt"},  # "I'm learning to program. Any tips?"
            {"content": "Technology should bring people together, not divide them.", "language": "en"}
        ]
    },
    {
        "topic": "Travel & Adventure",
        "messages": [
            {"content": "أين هو وجهة السفر المفضلة لديك؟", "language": "ar"},  # "Where is your favorite travel destination?"
            {"content": "¿Cuál es tu destino de viaje favorito?", "language": "es"},  # "What's your favorite travel destination?"
            {"content": "Où aimeriez-vous voyager?", "language": "fr"},  # "Where would you like to travel?"
            {"content": "来年日本に旅行する予定です。おすすめの場所はありますか？", "language": "ja"},  # "I'm planning to travel to Japan next year. Do you have any recommended places?"
            {"content": "As praias brasileiras são lindas!", "language": "pt"},  # "Brazilian beaches are beautiful!"
            {"content": "Wo würden Sie gerne hinreisen?", "language": "de"},  # "Where would you like to travel?"
            {"content": "I'd love to experience the desert in the Middle East.", "language": "en"},
            {"content": "Adoro viaggiare e scoprire nuove culture", "language": "it"},  # "I love traveling and discovering new cultures"
            {"content": "السياحة تفتح العقل على وجهات نظر جديدة", "language": "ar"},  # "Travel opens the mind to new perspectives"
            {"content": "He ahorrado mucho dinero para viajar", "language": "es"},  # "I've saved a lot of money to travel"
            {"content": "What's your favorite travel memory?", "language": "en"},
            {"content": "旅行是我最喜欢的事情", "language": "zh"},  # "Traveling is my favorite thing"
            {"content": "Traveling solo taught me so much about myself.", "language": "en"}
        ]
    },
    {
        "topic": "Food & Cuisine",
        "messages": [
            {"content": "أتعلم طبخ الأطباق العربية. أي وصفات تنصح بها؟", "language": "ar"},  # "I'm learning to cook Arabic dishes. What recipes do you recommend?"
            {"content": "¿Me puedes recomendar alguna receta tradicional?", "language": "es"},  # "Can you recommend a traditional recipe?"
            {"content": "J'adore la cuisine française!", "language": "fr"},  # "I love French cuisine!"
            {"content": "日本料理はとても美しく盛り付けられています", "language": "ja"},  # "Japanese cuisine is very beautifully presented"
            {"content": "A comida brasileira é muito diversa e saborosa!", "language": "pt"},  # "Brazilian food is very diverse and flavorful!"
            {"content": "Was ist dein Lieblingsgericht?", "language": "de"},  # "What's your favorite dish?"
            {"content": "Amo provare cibi da tutto il mondo", "language": "it"},  # "I love trying foods from all over the world"
            {"content": "الطبخ يجمع الناس من جميع الثقافات", "language": "ar"},  # "Cooking brings people together from all cultures"
            {"content": "La comida une a las personas", "language": "es"},  # "Food brings people together"
            {"content": "I love trying new spices and flavors from different cultures.", "language": "en"},
            {"content": "我喜欢尝试不同的美食", "language": "zh"},  # "I like trying different foods"
            {"content": "Food tells such interesting stories about culture!", "language": "en"}
        ]
    },
    {
        "topic": "Music & Arts",
        "messages": [
            {"content": "الموسيقى العربية لها ألحان جميلة جداً", "language": "ar"},  # "Arabic music has very beautiful melodies"
            {"content": "¿Qué tipo de música te gusta?", "language": "es"},  # "What type of music do you like?"
            {"content": "J'adore la musique classique", "language": "fr"},  # "I love classical music"
            {"content": "日本の伝統楽器を学んでいます", "language": "ja"},  # "I'm learning traditional Japanese instruments"
            {"content": "A música brasileira me faz querer dançar!", "language": "pt"},  # "Brazilian music makes me want to dance!"
            {"content": "Welche Art von Musik hörst du am liebsten?", "language": "de"},  # "What kind of music do you listen to most?"
            {"content": "Amo l'arte e la musica", "language": "it"},  # "I love art and music"
            {"content": "أحب كيف تربط الموسيقى الناس عبر الثقافات", "language": "ar"},  # "I love how music connects people across cultures"
            {"content": "El arte trasciende las barreras del idioma", "language": "es"},  # "Art transcends language barriers"
            {"content": "La danza tradicional es muy expresiva", "language": "es"},  # "Traditional dance is very expressive"
            {"content": "Music is truly a universal language!", "language": "en"}
        ]
    },
    {
        "topic": "🌍 Global Adventures",
        "messages": [
            {"content": "ما هي أكثر مغامرة مثيرة خضتها؟ 🏔️", "language": "ar"},  # "What is the most exciting adventure you've had?"
            {"content": "¿Cuál ha sido tu aventura más emocionante? 🏔️", "language": "es"},  # "What has been your most exciting adventure?"
            {"content": "Quelle a été votre aventure la plus passionnante? 🏔️", "language": "fr"},  # "What has been your most exciting adventure?"
            {"content": "I climbed Mount Fuji in Japan! 🇯🇵", "language": "en"},
            {"content": "انأ استكشفت غابات الأمازون في البرازيل! 🇧🇷", "language": "ar"},  # "I explored the Amazon rainforest in Brazil!"
            {"content": "Quiero hacer un safari en Kenia! 🦁", "language": "es"},  # "I want to go on a safari in Kenya!"
            {"content": "Me encantaría ver la aurora boreal en Noruega! 🌌", "language": "es"},  # "I'd love to see the Northern Lights in Norway!"
            {"content": "L'aventure est la meilleure façon d'apprendre! ✈️", "language": "fr"},  # "Adventure is the best way to learn!"
            {"content": "What's on your adventure bucket list? 🎒", "language": "en"},
            {"content": "Estoy planeando viajar por el sudeste asiático! 🎒", "language": "es"},  # "I'm planning to travel through Southeast Asia!"
            {"content": "The world is full of amazing adventures waiting! 🌍", "language": "en"}
        ]
    },
    {
        "topic": "🏛️ World Heritage Wonders",
        "messages": [
            {"content": "What UNESCO World Heritage sites have you visited? 🏛️", "language": "en"},
            {"content": "أي مواقع تراث عالمي زرتها؟ 🏛️", "language": "ar"},  # "What World Heritage sites have you visited?"
            {"content": "I visited the Taj Mahal in India - it's breathtaking! 🇮🇳", "language": "en"},
            {"content": "The Great Wall of China is incredible! 🇨🇳", "language": "en"},
            {"content": "Machu Picchu in Peru is on my bucket list! 🇵🇪", "language": "en"},
            {"content": "I want to see the Pyramids of Giza! 🇪🇬", "language": "en"},
            {"content": "The Colosseum in Rome is amazing! 🇮🇹", "language": "en"},
            {"content": "These sites tell the story of human civilization! 📚", "language": "en"},
            {"content": "What's your dream heritage site to visit? ✈️", "language": "en"},
            {"content": "I'd love to see Petra in Jordan! 🇯🇴", "language": "en"},
            {"content": "Stonehenge in England is mysterious! 🇬🇧", "language": "en"},
            {"content": "Let's plan visits to these amazing places! 🌍", "language": "en"},
            {"content": "The world's history is so rich and diverse! ✨", "language": "en"}
        ]
    },
    {
        "topic": "🎉 Festivals & Celebrations",
        "messages": [
            {"content": "What festivals do you celebrate in your country? 🎉", "language": "en"},
            {"content": "ما المهرجانات التي تحتفل بها في بلدك؟ 🎉", "language": "ar"},  # "What festivals do you celebrate in your country?"
            {"content": "I love the Cherry Blossom Festival in Japan! 🌸", "language": "en"},
            {"content": "Brazilian Carnival is so colorful and fun! 🇧🇷", "language": "en"},
            {"content": "Ramadan is a beautiful time of reflection! 🌙", "language": "en"},
            {"content": "I want to experience Diwali in India! 🪔", "language": "en"},
            {"content": "Festivals bring communities together! 🤝", "language": "en"},
            {"content": "What's your favorite holiday tradition? 🎊", "language": "en"},
            {"content": "I love how different cultures celebrate! 🌍", "language": "en"},
            {"content": "Let's share photos of our celebrations! 📸", "language": "en"},
            {"content": "Festivals are windows into culture! 👀", "language": "en"},
            {"content": "The world's celebrations are so diverse! ✨", "language": "en"}
        ]
    },
    {
        "topic": "🌅 Daily Life Around the World",
        "messages": [
            {"content": "What's a typical day like in your country? 🌅", "language": "en"},
            {"content": "كيف تبدو يوم عادي في بلدك؟ 🌅", "language": "ar"},  # "What does a typical day look like in your country?"
            {"content": "I wake up early in Japan for work! 🇯🇵", "language": "en"},
            {"content": "In Brazil, we have a big lunch and late dinner! 🇧🇷", "language": "en"},
            {"content": "In the UAE, we have afternoon tea breaks! 🇦🇪", "language": "en"},
            {"content": "What time do you usually eat dinner? 🍽️", "language": "en"},
            {"content": "I love learning about daily routines! 📅", "language": "en"},
            {"content": "How do you commute to work? 🚌", "language": "en"},
            {"content": "What's your favorite part of the day? ☀️", "language": "en"},
            {"content": "Daily life varies so much around the world! 🌍", "language": "en"},
            {"content": "I'm fascinated by different work cultures! 💼", "language": "en"},
            {"content": "Let's share our daily schedules! 📱", "language": "en"},
            {"content": "The world's daily rhythms are beautiful! ✨", "language": "en"}
        ]
    },
    {
        "topic": "🏃‍♀️ Sports & Fitness Global",
        "messages": [
            {"content": "What sports are popular in your country? ⚽", "language": "en"},
            {"content": "ما الرياضات الشائعة في بلدك؟ ⚽", "language": "ar"},  # "What sports are popular in your country?"
            {"content": "Football (soccer) is huge in Brazil! 🇧🇷", "language": "en"},
            {"content": "Baseball is very popular in Japan! 🇯🇵", "language": "en"},
            {"content": "Cricket is loved in many countries! 🏏", "language": "en"},
            {"content": "I love watching the Olympics! 🌍", "language": "en"},
            {"content": "Martial arts are amazing! Karate, Taekwondo! 🥋", "language": "en"},
            {"content": "What's your favorite sport to play? 🏀", "language": "en"},
            {"content": "Sports bring people together! 🤝", "language": "en"},
            {"content": "I'm learning yoga from India! 🧘‍♀️", "language": "en"},
            {"content": "Let's do virtual workouts together! 💪", "language": "en"},
            {"content": "Fitness is universal! 🏃‍♀️", "language": "en"},
            {"content": "Healthy body, healthy mind! 🧠", "language": "en"}
        ]
    },
    {
        "topic": "🎨 Art & Creativity",
        "messages": [
            {"content": "What traditional art forms exist in your country? 🎨", "language": "en"},
            {"content": "ما أشكال الفن التقليدي في بلدك؟ 🎨", "language": "ar"},  # "What traditional art forms exist in your country?"
            {"content": "Japanese calligraphy is so beautiful! 🇯🇵", "language": "en"},
            {"content": "Arabic geometric patterns are amazing! 🇦🇪", "language": "en"},
            {"content": "Brazilian street art is so colorful! 🇧🇷", "language": "en"},
            {"content": "I love traditional Indian henna art! 🇮🇳", "language": "en"},
            {"content": "Chinese brush painting is so elegant! 🇨🇳", "language": "en"},
            {"content": "Let's share photos of local art! 📸", "language": "en"},
            {"content": "Art tells the story of our cultures! 📖", "language": "en"},
            {"content": "I'm learning traditional dance! 💃", "language": "en"},
            {"content": "Modern art is influenced by global cultures! 🌍", "language": "en"},
            {"content": "Let's create art together online! 🖼️", "language": "en"},
            {"content": "Art connects us across all boundaries! ✨", "language": "en"}
        ]
    },
    {
        "topic": "🌍 Climate & Nature",
        "messages": [
            {"content": "What's the climate like in your country? 🌤️", "language": "en"},
            {"content": "كيف هو المناخ في بلدك؟ 🌤️", "language": "ar"},  # "What is the climate like in your country?"
            {"content": "Japan has beautiful seasons! Spring, summer, autumn, winter! 🇯🇵", "language": "en"},
            {"content": "Brazil has tropical weather year-round! 🇧🇷", "language": "en"},
            {"content": "The UAE has hot summers and mild winters! 🇦🇪", "language": "en"},
            {"content": "I love how nature varies around the world! 🌿", "language": "en"},
            {"content": "What's your favorite season? 🍂", "language": "en"},
            {"content": "I want to see snow! ❄️", "language": "en"},
            {"content": "Climate affects culture and lifestyle! 🌍", "language": "en"},
            {"content": "Let's share photos of our local nature! 📸", "language": "en"},
            {"content": "The world's natural diversity is amazing! 🌺", "language": "en"},
            {"content": "We must protect our planet! 🌱", "language": "en"},
            {"content": "Nature connects us all! 🌍✨", "language": "en"}
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
    },
    {
        "prompt": "What are the most beautiful travel destinations around the world?",
        "result": """🔍 Research Results: What are the most beautiful travel destinations around the world?

**Continental Highlights:**

**🌍 Africa:**
- 🇲🇦 Morocco: Sahara Desert, Atlas Mountains, Marrakech souks
- 🇿🇦 South Africa: Cape Town, Kruger National Park, Table Mountain
- 🇪🇬 Egypt: Pyramids of Giza, Nile River, Red Sea coral reefs
- 🇰🇪 Kenya: Maasai Mara, Mount Kenya, Lamu Island

**🌍 Asia:**
- 🇯🇵 Japan: Cherry blossoms, Mount Fuji, ancient temples
- 🇹🇭 Thailand: Bangkok temples, Phuket beaches, Chiang Mai mountains
- 🇮🇳 India: Taj Mahal, Kerala backwaters, Rajasthan palaces
- 🇰🇷 South Korea: Seoul, Jeju Island, DMZ peace parks

**🌍 Europe:**
- 🇮🇹 Italy: Rome, Venice canals, Tuscany countryside
- 🇫🇷 France: Paris, Provence lavender fields, French Riviera
- 🇪🇸 Spain: Barcelona, Andalusia, Balearic Islands
- 🇬🇷 Greece: Santorini, Athens Acropolis, Mykonos

**🌍 Americas:**
- 🇧🇷 Brazil: Rio de Janeiro, Amazon rainforest, Iguazu Falls
- 🇺🇸 USA: Grand Canyon, New York City, Hawaii volcanoes
- 🇨🇦 Canada: Banff National Park, Niagara Falls, Vancouver
- 🇦🇷 Argentina: Buenos Aires, Patagonia, Mendoza wine country

**🌍 Oceania:**
- 🇦🇺 Australia: Great Barrier Reef, Sydney Opera House, Outback
- 🇳🇿 New Zealand: Milford Sound, Rotorua geysers, Queenstown

**Travel Tips**: Each destination offers unique cultural experiences, local cuisines, and unforgettable memories! 🌟"""
    },
    {
        "prompt": "What are the best foods to try when traveling internationally?",
        "result": """🔍 Research Results: What are the best foods to try when traveling internationally?

**Continental Culinary Adventures:**

**🌍 Africa:**
- 🇲🇦 Morocco: Tagine, couscous, mint tea, pastilla
- 🇪🇹 Ethiopia: Injera bread, doro wat, coffee ceremony
- 🇿🇦 South Africa: Biltong, boerewors, malva pudding
- 🇳🇬 Nigeria: Jollof rice, suya, puff puff

**🌍 Asia:**
- 🇯🇵 Japan: Sushi, ramen, tempura, matcha tea
- 🇹🇭 Thailand: Pad Thai, tom yum soup, mango sticky rice
- 🇮🇳 India: Curry, naan bread, biryani, chai tea
- 🇰🇷 South Korea: Kimchi, bulgogi, bibimbap, Korean BBQ

**🌍 Europe:**
- 🇮🇹 Italy: Pizza, pasta, gelato, espresso
- 🇫🇷 France: Croissants, cheese, wine, macarons
- 🇪🇸 Spain: Paella, tapas, sangria, churros
- 🇩🇪 Germany: Bratwurst, pretzels, beer, Black Forest cake

**🌍 Americas:**
- 🇧🇷 Brazil: Feijoada, açaí, caipirinha, pão de açúcar
- 🇲🇽 Mexico: Tacos, guacamole, tequila, churros
- 🇺🇸 USA: BBQ, hamburgers, apple pie, craft beer
- 🇦🇷 Argentina: Asado, empanadas, Malbec wine, dulce de leche

**🌍 Oceania:**
- 🇦🇺 Australia: Vegemite, meat pies, Tim Tams, flat white coffee
- 🇳🇿 New Zealand: Pavlova, fish and chips, kiwi fruit, lamb

**Pro Tip**: Food is the best way to connect with local culture! 🍴✨"""
    },
    {
        "prompt": "What are the most interesting cultural festivals worldwide?",
        "result": """🔍 Research Results: What are the most interesting cultural festivals worldwide?

**Global Festival Calendar:**

**🌍 Africa:**
- 🇲🇦 Morocco: Festival of World Sacred Music (Fez) 🎵
- 🇿🇦 South Africa: Cape Town Jazz Festival 🎷
- 🇳🇬 Nigeria: Calabar Carnival 🎭
- 🇪🇹 Ethiopia: Timkat (Epiphany) celebration ⛪

**🌍 Asia:**
- 🇯🇵 Japan: Cherry Blossom Festival (Hanami) 🌸
- 🇹🇭 Thailand: Songkran Water Festival 💦
- 🇮🇳 India: Diwali Festival of Lights 🪔
- 🇰🇷 South Korea: Boryeong Mud Festival 🏖️

**🌍 Europe:**
- 🇪🇸 Spain: La Tomatina (Tomato Fight) 🍅
- 🇮🇹 Italy: Venice Carnival 🎭
- 🇩🇪 Germany: Oktoberfest 🍺
- 🇬🇧 UK: Glastonbury Music Festival 🎸

**🌍 Americas:**
- 🇧🇷 Brazil: Rio Carnival 🎊
- 🇲🇽 Mexico: Day of the Dead (Día de los Muertos) 💀
- 🇺🇸 USA: Mardi Gras (New Orleans) 🎭
- 🇦🇷 Argentina: Tango Festival 💃

**🌍 Oceania:**
- 🇦🇺 Australia: Sydney New Year's Eve 🎆
- 🇳🇿 New Zealand: Matariki (Māori New Year) ⭐

**Cultural Impact**: These festivals showcase unique traditions, music, dance, and community spirit! 🌟"""
    },
    {
        "prompt": "What are the best languages to learn for global travel?",
        "result": """🔍 Research Results: What are the best languages to learn for global travel?

**Top Languages for Global Travelers:**

**🌍 Most Spoken Worldwide:**
1. 🇨🇳 Mandarin Chinese: 1.1 billion speakers
2. 🇪🇸 Spanish: 500+ million speakers (Spain, Latin America)
3. 🇬🇧 English: 400+ million native speakers (global lingua franca)
4. 🇮🇳 Hindi: 600+ million speakers
5. 🇦🇷 Arabic: 400+ million speakers (Middle East, North Africa)

**🌍 Regional Powerhouses:**
- 🇫🇷 French: 280+ million speakers (France, Africa, Canada)
- 🇵🇹 Portuguese: 260+ million speakers (Brazil, Portugal, Africa)
- 🇷🇺 Russian: 260+ million speakers (Russia, Eastern Europe)
- 🇩🇪 German: 100+ million speakers (Germany, Austria, Switzerland)
- 🇯🇵 Japanese: 125+ million speakers (Japan, business hub)

**🌍 Emerging Travel Destinations:**
- 🇰🇷 Korean: 80+ million speakers (K-pop, K-drama influence)
- 🇹🇷 Turkish: 80+ million speakers (Turkey, Central Asia)
- 🇮🇹 Italian: 65+ million speakers (Italy, art, cuisine)
- 🇹🇭 Thai: 60+ million speakers (Thailand tourism)

**Travel Benefits**: Learning local languages enhances cultural immersion, safety, and authentic experiences! 🌟

**Pro Tip**: Start with English + Spanish + Mandarin for maximum global coverage! 🚀"""
    },
    {
        "prompt": "What are the most fascinating architectural wonders by continent?",
        "result": """🔍 Research Results: What are the most fascinating architectural wonders by continent?

**Continental Architectural Marvels:**

**🌍 Africa:**
- 🇪🇬 Egypt: Great Pyramids of Giza, Sphinx, Luxor Temple
- 🇲🇦 Morocco: Hassan II Mosque, Chefchaouen blue city
- 🇿🇦 South Africa: Table Mountain cableway, Cape Town waterfront
- 🇪🇹 Ethiopia: Rock-hewn churches of Lalibela

**🌍 Asia:**
- 🇮🇳 India: Taj Mahal, Red Fort, Lotus Temple
- 🇨🇳 China: Great Wall, Forbidden City, Terracotta Army
- 🇯🇵 Japan: Tokyo Skytree, Kiyomizu-dera Temple, Himeji Castle
- 🇰🇷 South Korea: Gyeongbokgung Palace, Lotte World Tower

**🌍 Europe:**
- 🇫🇷 France: Eiffel Tower, Notre-Dame, Palace of Versailles
- 🇮🇹 Italy: Colosseum, Leaning Tower of Pisa, Vatican City
- 🇪🇸 Spain: Sagrada Familia, Alhambra, Guggenheim Bilbao
- 🇬🇧 UK: Big Ben, Stonehenge, Buckingham Palace

**🌍 Americas:**
- 🇵🇪 Peru: Machu Picchu, Nazca Lines, Cusco Cathedral
- 🇧🇷 Brazil: Christ the Redeemer, Brasília architecture
- 🇺🇸 USA: Statue of Liberty, Golden Gate Bridge, Empire State Building
- 🇲🇽 Mexico: Chichen Itza, Palacio de Bellas Artes

**🌍 Oceania:**
- 🇦🇺 Australia: Sydney Opera House, Harbour Bridge, Parliament House
- 🇳🇿 New Zealand: Sky Tower, Beehive Parliament, Auckland War Memorial

**Architectural Impact**: These structures represent human creativity, engineering marvels, and cultural heritage! ✨"""
    },
    {
        "prompt": "What are the most exciting adventure activities worldwide?",
        "result": """🔍 Research Results: What are the most exciting adventure activities worldwide?

**Global Adventure Activities:**

**🌍 Africa:**
- 🇿🇦 South Africa: Safari in Kruger National Park 🦁
- 🇲🇦 Morocco: Camel trekking in Sahara Desert 🐪
- 🇰🇪 Kenya: Hot air balloon over Maasai Mara 🎈
- 🇪🇬 Egypt: Scuba diving in Red Sea 🐠

**🌍 Asia:**
- 🇳🇵 Nepal: Mount Everest base camp trek 🏔️
- 🇯🇵 Japan: Skiing in Hokkaido ⛷️
- 🇹🇭 Thailand: Rock climbing in Railay Beach 🧗
- 🇮🇳 India: White water rafting in Rishikesh 🚣

**🌍 Europe:**
- 🇨🇭 Switzerland: Paragliding in Interlaken 🪂
- 🇳🇴 Norway: Northern Lights viewing 🌌
- 🇮🇸 Iceland: Glacier hiking and ice caves 🧊
- 🇪🇸 Spain: Running of the Bulls in Pamplona 🐂

**🌍 Americas:**
- 🇧🇷 Brazil: Hang gliding in Rio de Janeiro 🪂
- 🇺🇸 USA: Skydiving in Las Vegas 🪂
- 🇨🇦 Canada: Dog sledding in Yukon 🐕
- 🇦🇷 Argentina: Ice trekking on Perito Moreno Glacier 🧊

**🌍 Oceania:**
- 🇳🇿 New Zealand: Bungee jumping in Queenstown 🦘
- 🇦🇺 Australia: Surfing in Bondi Beach 🏄
- 🇫🇯 Fiji: Shark diving in Beqa Lagoon 🦈

**Adventure Benefits**: These activities provide adrenaline rushes, unique perspectives, and unforgettable memories! 🚀"""
    }
]

# Group conversation topics
GROUP_CONVERSATIONS = [
    {
        "name": "Global Language Exchange",
        "description": "International language learning community",
        "messages": [
            {"content": "مرحباً بالجميع! دعونا نتشارك رحلاتنا في تعلم اللغات! 🌍", "language": "ar"},  # "Welcome everyone! Let's share our language learning journeys! 🌍"
            {"content": "¡Bienvenidos! Compartamos nuestros viajes de aprendizaje! 🌍", "language": "es"},  # "Welcome! Let's share our learning journeys!"
            {"content": "Bienvenue à tous! Partageons nos expériences! 🌍", "language": "fr"},  # "Welcome everyone! Let's share our experiences!"
            {"content": "このグループで学べるのがとても楽しみです！", "language": "ja"},  # "I'm very excited to learn in this group!"
            {"content": "Esta es una comunidad tan diversa - ¡podemos aprender mucho!", "language": "es"},  # "This is such a diverse community - we can learn a lot!"
            {"content": "A tecnologia nos conecta de forma incrível!", "language": "pt"},  # "Technology connects us in an incredible way!"
            {"content": "¿Alguien quiere practicar hablando juntos?", "language": "es"},  # "Does anyone want to practice speaking together?"
            {"content": "J'adore comment la technologie nous réunit!", "language": "fr"},  # "I love how technology brings us together!"
            {"content": "Was ist das Interessanteste, das du über eine andere Kultur gelernt hast?", "language": "de"},  # "What's the most interesting thing you've learned about another culture?"
            {"content": "Let's organize a virtual cultural exchange event!", "language": "en"},
            {"content": "Je suis reconnaissant de faire partie de cette communauté!", "language": "fr"},  # "I'm grateful to be part of this community!"
            {"content": "Language learning is so much more fun with friends!", "language": "en"},
            {"content": "Gracias a todos por compartir sus experiencias! 🙏", "language": "es"}  # "Thank you all for sharing your experiences! 🙏"
        ]
    },
    {
        "name": "Language Learning with Tutor",
        "description": "Structured learning sessions with professional tutor",
        "messages": [
            {"content": "Welcome to our language learning session! I'm excited to work with all of you today.", "language": "en"},
            {"content": "Let's start with a quick introduction. Please tell us your name and what language you're learning.", "language": "en"},
            {"content": "Hi! I'm Aisha and I'm learning English. I'm from the UAE.", "language": "en"},
            {"content": "Hello! I'm Kenji from Japan. I'm studying English and Portuguese.", "language": "en"},
            {"content": "Olá! I'm Isabella from Brazil. I'm learning English and Japanese.", "language": "en"},
            {"content": "Excellent! What a diverse group. Today we'll focus on conversational practice.", "language": "en"},
            {"content": "Let's practice describing our daily routines. Who would like to start?", "language": "en"},
            {"content": "I wake up at 6 AM and have breakfast with my family.", "language": "en"},
            {"content": "Great! Notice how Aisha used 'wake up' - that's a common phrasal verb.", "language": "en"},
            {"content": "I work in technology and love learning new languages!", "language": "en"},
            {"content": "Perfect! Let's practice asking follow-up questions. Kenji, what do you do for work?", "language": "en"},
            {"content": "I'm a software engineer. I create mobile applications.", "language": "en"},
            {"content": "Wonderful! You're all making great progress. Let's continue with cultural exchange.", "language": "en"},
            {"content": "This session has been very helpful. Thank you!", "language": "en"}
        ]
    },
    {
        "name": "Cultural Explorers",
        "description": "Sharing cultural experiences and traditions",
        "messages": [
            {"content": "أخبرونا عن تقليد فريد من بلدكم!", "language": "ar"},  # "Tell us about a unique tradition from your country!"
            {"content": "Cuéntanos sobre una tradición única de tu país!", "language": "es"},  # "Tell us about a unique tradition from your country!"
            {"content": "Je suis fasciné par les différentes cultures!", "language": "fr"},  # "I'm fascinated by different cultures!"
            {"content": "A comida é uma ótima forma de aprender sobre cultura!", "language": "pt"},  # "Food is a great way to learn about culture!"
            {"content": "¿Cuál es tu festival cultural favorito?", "language": "es"},  # "What's your favorite cultural festival?"
            {"content": "Me encanta aprender sobre música y danza tradicional!", "language": "es"},  # "I love learning about traditional music and dance!"
            {"content": "文化の交換は世界をより美しくします", "language": "ja"},  # "Cultural exchange makes the world more beautiful"
            {"content": "Compartamos fotos de nuestras celebraciones culturales!", "language": "es"},  # "Let's share photos of our cultural celebrations!"
            {"content": "Je veux visiter tous vos pays un jour!", "language": "fr"},  # "I want to visit all your countries one day!"
            {"content": "Every culture has such beautiful stories to tell!", "language": "en"},
            {"content": "¡Este grupo es como una ventana al mundo! 🌎", "language": "es"}  # "This group is like a window to the world!"
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
    },
    {
        "name": "🌍 Global Travelers",
        "description": "Sharing travel experiences and bucket list destinations",
        "messages": [
            {"content": "أين وجهة السفر التي تحلم بها؟ ✈️", "language": "ar"},  # "Where is your dream travel destination?"
            {"content": "¿Cuál es tu destino de viaje soñado? ✈️", "language": "es"},  # "What's your dream travel destination?"
            {"content": "Où est votre destination de voyage de rêve? ✈️", "language": "fr"},  # "Where is your dream travel destination?"
            {"content": "Vorrei visitare il Giappone durante la stagione dei ciliegi! 🌸", "language": "it"},  # "I want to visit Japan during cherry blossom season!"
            {"content": "Me encantaría explorar la selva amazónica en Brasil! 🌳", "language": "es"},  # "I'd love to explore the Amazon rainforest in Brazil!"
            {"content": "Las pirámides de Egipto están en mi lista de deseos! 🏺", "language": "es"},  # "The pyramids in Egypt are on my bucket list!"
            {"content": "Estou planejando uma viagem ao Marrocos no ano que vem! 🇲🇦", "language": "pt"},  # "I'm planning a trip to Morocco next year!"
            {"content": "Alguém já foi à Tailândia? Preciso de recomendações! 🇹🇭", "language": "pt"},  # "Has anyone been to Thailand? I need recommendations!"
            {"content": "Quiero ver la aurora boreal en Noruega! 🌌", "language": "es"},  # "I want to see the Northern Lights in Norway!"
            {"content": "La muraille de Chine est incroyable! 🇨🇳", "language": "fr"},  # "The Great Wall of China is incredible!"
            {"content": "Traveling solo is so empowering! 💪", "language": "en"},
            {"content": "El mundo es tan hermoso y diverso! 🌍✨", "language": "es"}  # "The world is so beautiful and diverse!"
        ]
    },
    {
        "name": "🍕 Food Around the World",
        "description": "Exploring international cuisines and culinary traditions",
        "messages": [
            {"content": "What's your favorite international dish? 🍽️", "language": "en"},
            {"content": "ما هو طبقك الدولي المفضل؟ 🍽️", "language": "ar"},  # "What is your favorite international dish?"
            {"content": "I love Japanese ramen! It's so comforting 🍜", "language": "en"},
            {"content": "Brazilian feijoada is amazing! 🇧🇷", "language": "en"},
            {"content": "Have you tried Moroccan tagine? It's delicious! 🇲🇦", "language": "en"},
            {"content": "I'm learning to make authentic Italian pasta! 🇮🇹", "language": "en"},
            {"content": "Korean BBQ is incredible! The flavors are amazing 🇰🇷", "language": "en"},
            {"content": "I want to try authentic Indian curry! 🇮🇳", "language": "en"},
            {"content": "French pastries are works of art! 🇫🇷", "language": "en"},
            {"content": "Mexican tacos are perfect street food! 🇲🇽", "language": "en"},
            {"content": "Food brings people together across cultures! 🤝", "language": "en"},
            {"content": "Let's share recipes from our countries! 📝", "language": "en"},
            {"content": "Cooking is like learning a new language! 👨‍🍳", "language": "en"}
        ]
    },
    {
        "name": "🎵 Music & Dance Global",
        "description": "Sharing music and dance traditions from around the world",
        "messages": [
            {"content": "What music do you listen to from your country? 🎵", "language": "en"},
            {"content": "أي موسيقى تستمع إليها من بلدك؟ 🎵", "language": "ar"},  # "What music do you listen to from your country?"
            {"content": "I love Brazilian samba! It's so energetic! 🇧🇷", "language": "en"},
            {"content": "Japanese anime music is beautiful! 🇯🇵", "language": "en"},
            {"content": "Arabic music has such beautiful melodies! 🇦🇪", "language": "en"},
            {"content": "I'm learning traditional Japanese dance! 💃", "language": "en"},
            {"content": "Capoeira from Brazil is amazing! It's martial arts and dance! 🇧🇷", "language": "en"},
            {"content": "I love K-pop! The choreography is incredible! 🇰🇷", "language": "en"},
            {"content": "Flamenco from Spain is so passionate! 🇪🇸", "language": "en"},
            {"content": "Music transcends language barriers! 🌍", "language": "en"},
            {"content": "Let's share playlists from our countries! 📱", "language": "en"},
            {"content": "Dancing is universal! Everyone can dance! 💃🕺", "language": "en"},
            {"content": "Music connects hearts across the world! ❤️", "language": "en"}
        ]
    },
    {
        "name": "🏛️ World Heritage Sites",
        "description": "Discussing UNESCO World Heritage sites and cultural landmarks",
        "messages": [
            {"content": "What World Heritage sites have you visited? 🏛️", "language": "en"},
            {"content": "أي مواقع تراث عالمي زرتها؟ 🏛️", "language": "ar"},  # "What World Heritage sites have you visited?"
            {"content": "The Taj Mahal in India is breathtaking! 🇮🇳", "language": "en"},
            {"content": "Machu Picchu in Peru is incredible! 🇵🇪", "language": "en"},
            {"content": "I want to see the Great Wall of China! 🇨🇳", "language": "en"},
            {"content": "The Colosseum in Rome is amazing! 🇮🇹", "language": "en"},
            {"content": "Stonehenge in England is mysterious! 🇬🇧", "language": "en"},
            {"content": "The Pyramids of Giza are ancient wonders! 🇪🇬", "language": "en"},
            {"content": "I'd love to visit Petra in Jordan! 🇯🇴", "language": "en"},
            {"content": "These sites tell the story of human civilization! 📚", "language": "en"},
            {"content": "Let's plan visits to these amazing places! ✈️", "language": "en"},
            {"content": "Preserving heritage is so important! 🛡️", "language": "en"},
            {"content": "The world's history is so rich and diverse! 🌍", "language": "en"}
        ]
    },
    {
        "name": "🌅 Sunrise to Sunset",
        "description": "Sharing daily life and routines from different time zones",
        "messages": [
            {"content": "What time is it where you are? 🌅", "language": "en"},
            {"content": "كم الساعة عندك؟ 🌅", "language": "ar"},  # "What time is it where you are?"
            {"content": "It's morning here in Japan! Good morning everyone! 🇯🇵", "language": "en"},
            {"content": "Good evening from Brazil! 🇧🇷", "language": "en"},
            {"content": "It's afternoon here in the UAE! 🇦🇪", "language": "en"},
            {"content": "I'm having breakfast while you're having dinner! 🍳", "language": "en"},
            {"content": "The sun is setting here, beautiful colors! 🌇", "language": "en"},
            {"content": "I'm starting my day while you're ending yours! ☀️", "language": "en"},
            {"content": "Time zones are so fascinating! ⏰", "language": "en"},
            {"content": "We're all connected despite different times! 🌍", "language": "en"},
            {"content": "Let's share photos of our sunrises and sunsets! 📸", "language": "en"},
            {"content": "The world never sleeps! 🌙", "language": "en"},
            {"content": "Good morning, afternoon, and evening to all! 👋", "language": "en"}
        ]
    },
    {
        "name": "🎨 Art & Culture Exchange",
        "description": "Sharing traditional and modern art from different cultures",
        "messages": [
            {"content": "What traditional art forms exist in your country? 🎨", "language": "en"},
            {"content": "ما هي أشكال الفن التقليدي في بلدك؟ 🎨", "language": "ar"},  # "What traditional art forms exist in your country?"
            {"content": "Japanese calligraphy is so beautiful! 🇯🇵", "language": "en"},
            {"content": "Arabic geometric patterns are amazing! 🇦🇪", "language": "en"},
            {"content": "Brazilian street art is so colorful! 🇧🇷", "language": "en"},
            {"content": "I love traditional Indian henna art! 🇮🇳", "language": "en"},
            {"content": "Chinese brush painting is so elegant! 🇨🇳", "language": "en"},
            {"content": "Let's share photos of local art! 📸", "language": "en"},
            {"content": "Art tells the story of our cultures! 📖", "language": "en"},
            {"content": "I'm learning traditional dance from my country! 💃", "language": "en"},
            {"content": "Modern art is influenced by global cultures! 🌍", "language": "en"},
            {"content": "Let's create art together online! 🖼️", "language": "en"},
            {"content": "Art connects us across all boundaries! ✨", "language": "en"}
        ]
    },
    {
        "name": "🏃‍♀️ Sports & Fitness Global",
        "description": "Discussing sports and fitness traditions worldwide",
        "messages": [
            {"content": "What sports are popular in your country? ⚽", "language": "en"},
            {"content": "ما الرياضات الشائعة في بلدك؟ ⚽", "language": "ar"},  # "What sports are popular in your country?"
            {"content": "Football (soccer) is huge in Brazil! 🇧🇷", "language": "en"},
            {"content": "Baseball is very popular in Japan! 🇯🇵", "language": "en"},
            {"content": "Cricket is loved in many countries! 🏏", "language": "en"},
            {"content": "I love watching the Olympics! 🌍", "language": "en"},
            {"content": "Martial arts are amazing! Karate, Taekwondo, Capoeira! 🥋", "language": "en"},
            {"content": "Let's share our favorite sports! 🏀", "language": "en"},
            {"content": "Sports bring people together! 🤝", "language": "en"},
            {"content": "I'm learning yoga from India! 🧘‍♀️", "language": "en"},
            {"content": "Let's do virtual workouts together! 💪", "language": "en"},
            {"content": "Fitness is universal! 🏃‍♀️", "language": "en"},
            {"content": "Healthy body, healthy mind! 🧠", "language": "en"}
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
            for existing_user in self.existing_users[:6]:  # Increased to 6 conversations per demo user
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
        
        # Create special group chat with all demo users and a tutor
        if len(self.created_users) >= 3:
            # Find a tutor from existing users
            tutor_user = None
            for existing_user in self.existing_users:
                if existing_user.get("isTutor", False):
                    tutor_user = existing_user
                    break
            
            if tutor_user:
                # Create group with all demo users + tutor
                participants = self.created_users + [tutor_user["id"]]
                participant_names = {}
                
                for user_id in participants:
                    if user_id in demo_user_names:
                        participant_names[user_id] = demo_user_names[user_id]
                    else:
                        participant_names[user_id] = tutor_user["displayName"]
                
                conv_id = f"demo_group_{conv_count}"
                conv_count += 1
                
                conversation_data = {
                    "id": conv_id,
                    "participantIds": participants,
                    "participantNames": participant_names,
                    "isGroup": True,
                    "groupName": "Language Learning with Tutor",
                    "groupImageUrl": f"https://i.pravatar.cc/150?img={30 + conv_count}",
                    "createdAt": SERVER_TIMESTAMP,
                    "updatedAt": SERVER_TIMESTAMP,
                    "unreadCount": 0
                }
                
                self.db.collection("conversations").document(conv_id).set(conversation_data)
                conversation_ids.append(conv_id)
                
                print(f"👥 Created tutor group: Language Learning with Tutor (with {tutor_user['displayName']})")
        
        # Create additional group conversations (doubled)
        if len(all_users) >= 3:
            # Create twice as many groups
            for group_data in GROUP_CONVERSATIONS * 2:  # Double the groups
                conv_id = f"demo_group_{conv_count}"
                conv_count += 1
                
                # Special handling for Music & Dance Global channel - ensure all demo users are included
                if group_data["name"] == "🎵 Music & Dance Global":
                    # Always include all demo users in this channel
                    participants = self.created_users.copy()
                    # Add 1-2 additional random users if available
                    remaining_users = [u for u in all_users if u not in self.created_users]
                    if remaining_users:
                        additional_count = min(random.randint(1, 2), len(remaining_users))
                        participants.extend(random.sample(remaining_users, additional_count))
                else:
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
                
                # Special debug output for Music & Dance Global channel
                if group_data["name"] == "🎵 Music & Dance Global":
                    demo_user_count = sum(1 for uid in participants if uid in self.created_users)
                    print(f"👥 Created group: {group_data['name']} (ALL 3 DEMO USERS INCLUDED! ✅) - Total participants: {len(participants)}, Demo users: {demo_user_count}")
                else:
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
            
            # Select appropriate message pool based on conversation type
            if is_group:
                group_name = conv_data.get("groupName", "")
                # Find matching group conversation template
                group_template = None
                for group_template_candidate in GROUP_CONVERSATIONS:
                    if group_template_candidate["name"] == group_name:
                        group_template = group_template_candidate
                        break
                
                if group_template:
                    messages_to_add = random.sample(group_template["messages"], min(random.randint(8, 15), len(group_template["messages"])))
                else:
                    # Fallback to regular conversation topics
                    topic = random.choice(CONVERSATION_TOPICS)
                    messages_to_add = random.sample(topic["messages"], min(random.randint(5, 10), len(topic["messages"])))
            else:
                # One-on-one conversations
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
                    "conversationId": conv_id,  # Required by Swift app
                    "senderId": sender,
                    "content": content,
                    "timestamp": SERVER_TIMESTAMP,  # Use Firestore timestamp
                    "status": "sent",  # Required by Swift app
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
