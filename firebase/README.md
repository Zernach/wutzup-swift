# Firebase Configuration for Wutzup

This directory contains all Firebase configuration files, Cloud Functions, and database schema for the Wutzup messaging application.

## 📁 Directory Structure

```
firebase/
├── README.md                  # This file
├── SCHEMA.md                  # Complete Firestore schema documentation
├── firebase.json              # Firebase project configuration
├── firestore.rules            # Firestore security rules
├── firestore.indexes.json     # Firestore database indexes
├── seed_database.py          # Database seeding script for testing
└── functions/                 # Cloud Functions
    ├── main.py               # Cloud Functions implementation
    ├── requirements.txt      # Python dependencies
    └── venv/                 # Virtual environment (not tracked in git)
```

## 🚀 Quick Start

### Prerequisites

1. **Firebase CLI**
   ```bash
   npm install -g firebase-tools
   ```

2. **Python 3.13+** (for Cloud Functions)
   ```bash
   python --version  # Should be 3.13+
   ```

3. **Firebase Project**
   - Create a project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Firestore Database
   - Enable Authentication (Email/Password)
   - Enable Firebase Storage
   - Enable Cloud Messaging (FCM)

### Initial Setup

1. **Login to Firebase**
   ```bash
   firebase login
   ```

2. **Initialize Firebase** (if not already done)
   ```bash
   firebase init
   
   # Select:
   # - Firestore
   # - Functions
   # - Storage
   # - Emulators (optional but recommended)
   ```

3. **Set your Firebase project**
   ```bash
   firebase use YOUR_PROJECT_ID
   ```

## 🗄️ Firestore Database

### Schema Overview

The Firestore database uses the following collections:

```
firestore/
├── users/                    # User profiles
├── conversations/            # Chat conversations
│   └── messages/            # Messages (subcollection)
├── presence/                 # User online/offline status
└── typing/                   # Typing indicators
```

See **[SCHEMA.md](./SCHEMA.md)** for complete schema documentation with types and examples.

### Deploy Security Rules

```bash
# Test rules locally with emulator
firebase emulators:start --only firestore

# Deploy to production
firebase deploy --only firestore:rules
```

### Deploy Indexes

```bash
firebase deploy --only firestore:indexes
```

### Seeding Test Data

Use the `seed_database.py` script to populate your database with test data:

```bash
# Install dependencies
pip install firebase-admin

# Seed local emulator
python seed_database.py --emulator --clear

# Seed production (⚠️ use with caution!)
python seed_database.py --project-id YOUR_PROJECT_ID --clear
```

**Test Data Created:**
- 4 test users (Alice, Bob, Charlie, Diana)
- 3 conversations (2 one-on-one, 1 group chat)
- Sample messages in each conversation
- Presence data for all users

## ☁️ Cloud Functions

### Available Functions

1. **`on_message_created`** - Firestore trigger
   - Triggered when a new message is created
   - Sends push notifications to all recipients
   - Updates conversation metadata

2. **`on_conversation_created`** - Firestore trigger
   - Triggered when a new conversation is created
   - Logs conversation creation

3. **`on_presence_updated`** - Firestore trigger
   - Triggered when user presence changes
   - Logs status changes

4. **`test_notification`** - HTTP function
   - Test endpoint for sending push notifications
   - POST `/test_notification` with `userId`, `title`, `body`

5. **`health_check`** - HTTP function
   - Health check endpoint
   - GET `/health_check`

### Deploy Cloud Functions

```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:on_message_created

# View logs
firebase functions:log
```

### Testing Functions Locally

```bash
# Start emulators (includes Functions emulator)
firebase emulators:start

# Functions will be available at:
# http://localhost:5001/YOUR_PROJECT_ID/us-central1/function_name
```

### Cloud Functions Dependencies

All dependencies are listed in `functions/requirements.txt`:
- `firebase_functions` - Firebase Functions SDK
- `firebase-admin` - Firebase Admin SDK for server-side operations

## 🧪 Local Development with Emulators

### Start All Emulators

```bash
firebase emulators:start
```

This starts:
- **Firestore Emulator**: `localhost:8080`
- **Auth Emulator**: `localhost:9099`
- **Functions Emulator**: `localhost:5001`
- **Emulator UI**: `http://localhost:4000`

### Connect iOS App to Emulators

In your iOS app, configure Firestore to use the emulator:

```swift
#if DEBUG
let settings = Firestore.firestore().settings
settings.host = "localhost:8080"
settings.isSSLEnabled = false
Firestore.firestore().settings = settings

Auth.auth().useEmulator(withHost: "localhost", port: 9099)
Storage.storage().useEmulator(withHost: "localhost", port: 9199)
#endif
```

### Benefits of Emulators

- ✅ **Free** - No Firebase usage costs
- ✅ **Fast** - No network latency
- ✅ **Safe** - Can't accidentally corrupt production data
- ✅ **Offline** - Work without internet
- ✅ **Reset** - Easy to clear and start fresh

## 📊 Database Schema

### Users Collection

```typescript
/users/{userId}
{
  id: string
  email: string
  displayName: string
  profileImageUrl?: string
  fcmToken?: string
  createdAt: timestamp
  lastSeen?: timestamp
}
```

### Conversations Collection

```typescript
/conversations/{conversationId}
{
  id: string
  participantIds: string[]
  isGroup: boolean
  groupName?: string
  groupImageUrl?: string
  lastMessage?: string
  lastMessageTimestamp?: timestamp
  createdAt: timestamp
  updatedAt: timestamp
}
```

### Messages Subcollection

```typescript
/conversations/{conversationId}/messages/{messageId}
{
  id: string
  senderId: string
  content: string
  timestamp: timestamp
  mediaUrl?: string
  mediaType?: 'image' | 'video'
  readBy: string[]
  deliveredTo: string[]
}
```

See **[SCHEMA.md](./SCHEMA.md)** for complete details.

## 🔒 Security Rules

Security rules are defined in `firestore.rules`:

- **Users**: Read by any authenticated user, write by owner only
- **Conversations**: Read/write by participants only
- **Messages**: Read/write by conversation participants only
- **Presence**: Read by any authenticated user, write by owner only
- **Typing**: Read/write by any authenticated user

### Testing Security Rules

```bash
# Start emulator
firebase emulators:start --only firestore

# Run tests (if you have test files)
firebase emulators:exec "npm test"
```

## 📈 Indexes

Firestore indexes are defined in `firestore.indexes.json`:

1. **Conversations Index**
   - Fields: `participantIds` (array-contains), `lastMessageTimestamp` (desc)
   - Purpose: Query user's conversations ordered by recent activity

2. **Messages Index (Ascending)**
   - Fields: `timestamp` (asc)
   - Purpose: Display messages in chronological order

3. **Messages Index (Descending)**
   - Fields: `timestamp` (desc)
   - Purpose: Pagination and loading recent messages first

4. **Messages by Sender Index**
   - Fields: `senderId` (asc), `timestamp` (desc)
   - Purpose: Query messages by specific sender

## 🚢 Deployment

### Deploy Everything

```bash
firebase deploy
```

### Deploy Specific Components

```bash
# Firestore rules only
firebase deploy --only firestore:rules

# Firestore indexes only
firebase deploy --only firestore:indexes

# Cloud Functions only
firebase deploy --only functions

# Multiple components
firebase deploy --only firestore:rules,functions
```

### Check Deployment Status

```bash
# List deployed functions
firebase functions:list

# View recent logs
firebase functions:log

# Monitor in real-time
firebase functions:log --only on_message_created
```

## 💰 Cost Management

### Free Tier Limits (Spark Plan)

- **Firestore**: 50K reads/day, 20K writes/day, 1GB storage
- **Cloud Functions**: 125K invocations/month, 40K GB-seconds
- **Authentication**: Unlimited
- **Cloud Messaging**: Unlimited

### Paid Tier (Blaze Plan)

Required for production Cloud Functions usage.

**Pricing:**
- Firestore: $0.06 per 100K reads, $0.18 per 100K writes
- Cloud Functions: $0.40 per million invocations
- Storage: $0.026 per GB/month

### Set Budget Alerts

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Usage and billing**
4. Set up budget alerts

## 🧹 Maintenance

### Clear Test Data

```bash
python seed_database.py --emulator --clear
```

### View Firestore Data

```bash
# In browser (emulator UI)
firebase emulators:start
# Visit http://localhost:4000

# Or use Firebase Console
# https://console.firebase.google.com
```

### Backup Database

```bash
# Export Firestore data
gcloud firestore export gs://YOUR_BUCKET_NAME

# Import Firestore data
gcloud firestore import gs://YOUR_BUCKET_NAME/[PATH]
```

## 🐛 Troubleshooting

### "Permission Denied" Errors

1. Check security rules in `firestore.rules`
2. Ensure user is authenticated
3. Verify user is a participant in the conversation
4. Test with emulator to debug rules

### Cloud Functions Not Triggering

1. Check function is deployed: `firebase functions:list`
2. View logs: `firebase functions:log`
3. Verify trigger path matches collection structure
4. Check Firebase plan (Blaze required for production)

### Emulator Connection Issues

1. Ensure emulator is running: `firebase emulators:start`
2. Check iOS app emulator configuration
3. Verify firewall isn't blocking ports (8080, 9099, 5001)
4. Try restarting emulators

### Index Warnings

```
The query requires an index. You can create it here: [URL]
```

1. Click the URL to create index automatically
2. Or add to `firestore.indexes.json` and deploy
3. Wait 5-10 minutes for index to build

## 📚 Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Cloud Functions for Python](https://firebase.google.com/docs/functions/get-started?gen=2nd)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)
- [Firestore Data Modeling](https://firebase.google.com/docs/firestore/data-model)

## 🆘 Support

For issues or questions:
1. Check [SCHEMA.md](./SCHEMA.md) for database structure
2. Review Firebase Console logs
3. Test with emulator first
4. Check security rules are correctly deployed

---

**Last Updated:** October 21, 2025  
**Firebase SDK Version:** Python 3.13  
**Firestore Rules Version:** 2

