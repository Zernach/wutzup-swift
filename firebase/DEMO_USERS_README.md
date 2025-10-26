# Demo User Generation Script

This script creates three diverse international demo users with authentic names, profile images, personalities, and dozens of sample conversations including research features for demo purposes.

## 🎯 Demo Users Created

### 1. Aisha Al-Zahra (UAE)
- **Email**: aisha.alzahra@demo.wutzup.app
- **Languages**: Arabic (primary), English (learning)
- **Personality**: Warm and intelligent Arabic tutor from Dubai with a passion for Middle Eastern culture and literature
- **Interests**: Arabic literature, calligraphy, poetry, Middle Eastern culture, teaching

### 2. Kenji Nakamura (Japan)
- **Email**: kenji.nakamura@demo.wutzup.app
- **Languages**: Japanese (primary), English (learning)
- **Personality**: Methodical and creative Japanese software engineer from Tokyo who loves anime, manga, and traditional tea ceremony
- **Interests**: anime, manga, programming, tea ceremony, technology

### 3. Isabella Santos (Brazil)
- **Email**: isabella.santos@demo.wutzup.app
- **Languages**: Portuguese (primary), English (learning)
- **Personality**: Vibrant Brazilian marketing professional from São Paulo with a love for samba, capoeira, and Brazilian cuisine
- **Interests**: samba, capoeira, Brazilian cuisine, marketing, sustainability

## 🚀 Usage

### Prerequisites
```bash
pip install firebase-admin
```

### With Production Database
```bash
cd firebase
python3 generate_demo_users.py --project-id YOUR_PROJECT_ID
```

### With Local Emulator
```bash
cd firebase
firebase emulators:start  # Start emulator first
python3 generate_demo_users.py --emulator
```

## 📊 What Gets Created

### Users
- 3 diverse international demo users
- Authentic names and personalities
- Profile images from Pravatar
- Language preferences and cultural backgrounds

### Conversations
- One-on-one chats between demo users and existing users
- Conversations between demo users
- Group conversations with diverse topics:
  - Global Language Exchange
  - Cultural Explorers
  - Tech Innovators

### Messages
- 5-10 messages per conversation
- **~50% Foreign Language Messages**: Arabic, Japanese, and Portuguese with proper language tagging
- Diverse topics: Language Learning, Cultural Exchange, Technology, Travel, Food, Music & Arts
- **Translation Feature Showcase**: Messages in Arabic (أحب كيف أن الخط العربي جميل جداً), Japanese (日本語の敬語は本当に複雑ですね), and Portuguese (A pronúncia do português é difícil, mas estou melhorando!)
- **Research Results**: Some conversations include AI-generated research on:
  - Latest trends in language learning technology
  - How cultural background influences communication styles
  - Benefits of multilingualism for cognitive development

### Features Showcased
- ✅ International diversity
- ✅ Language learning focus
- ✅ Cultural exchange
- ✅ **Translation functionality** (50% foreign language messages)
- ✅ Research functionality
- ✅ Group conversations
- ✅ Realistic message patterns
- ✅ User presence (online status)

## 🔑 Login Credentials

**Demo User Login Information:**

| User | Email | Password |
|------|-------|----------|
| Aisha Al-Zahra | aisha.alzahra@demo.wutzup.app | password |
| Kenji Nakamura | kenji.nakamura@demo.wutzup.app | password |
| Isabella Santos | isabella.santos@demo.wutzup.app | password |

**Note**: All demo users are created with the password `password` for easy demo access.

## 🎬 Perfect for Demo Videos

This script creates realistic demo data that showcases:
- **International Appeal**: Users from UAE, Japan, and Brazil
- **Language Learning**: Each user has different language preferences
- **Cultural Exchange**: Conversations about traditions, food, music, travel
- **Research Features**: AI-generated research results in conversations
- **Diverse Content**: Multiple conversation topics and group chats
- **Realistic Patterns**: Natural message flow and read receipts

## 📝 Sample Content

### Language Learning Messages
- "I've been practicing Arabic calligraphy lately. The curves are so beautiful!"
- "Can you help me understand the difference between formal and informal Arabic?"
- "What's your favorite way to learn new vocabulary?"

### Cultural Exchange Messages
- "Tell me about traditional festivals in your country!"
- "أخبرني عن المهرجانات التقليدية في بلدك!" (Arabic: "Tell me about traditional festivals in your country!")
- "I'd love to visit Dubai someday. What should I see first?"
- "دبي مدينة رائعة! يجب أن تزور برج خليفة" (Arabic: "Dubai is a wonderful city! You should visit Burj Khalifa")
- "Brazilian music is incredible! I've been listening to bossa nova."
- "A música brasileira é incrível! Bossa nova é linda" (Portuguese: "Brazilian music is incredible! Bossa nova is beautiful")

### Research Results
The script includes AI-generated research on language learning technology, cultural communication patterns, and cognitive benefits of multilingualism - perfect for showcasing the app's research capabilities.

## 🔧 Customization

You can easily modify the script to:
- Add more demo users
- Change conversation topics
- Add different research topics
- Modify message content
- Adjust conversation patterns

The script is designed to be easily extensible and customizable for different demo scenarios.
