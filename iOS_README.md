# Wutzup iOS App

Real-time messaging iOS application built with SwiftUI and Firebase.

## 🚀 Quick Start

### 1. Create Xcode Project
See detailed instructions in [XCODE_SETUP.md](./XCODE_SETUP.md)

### 2. Add Source Files
All Swift files are in the `Wutzup/` directory. Import them into your Xcode project.

### 3. Add Firebase SDK
```
File → Add Package Dependencies
URL: https://github.com/firebase/firebase-ios-sdk
Select: FirebaseAuth, FirebaseFirestore, FirebaseStorage, FirebaseMessaging
```

### 4. Add GoogleService-Info.plist
Download from Firebase Console and add to `Wutzup/Resources/`

### 5. Run the App!
- Select iOS 16.0+ simulator or device
- Press Cmd + R

## 📁 Project Structure

```
Wutzup/
├── App/                  # App entry and global state
├── Models/
│   ├── Domain/           # Business models
│   └── SwiftData/        # Local cache models
├── Services/
│   ├── Protocols/        # Service interfaces
│   └── Firebase/         # Firebase implementations
├── ViewModels/           # MVVM ViewModels
├── Views/                # SwiftUI views
│   ├── Authentication/   # Login/Register
│   ├── ChatList/         # Conversation list
│   ├── Conversation/     # Chat interface
│   └── Components/       # Reusable components
├── Utilities/            # Helpers and extensions
└── Resources/            # Assets and config files
```

## 🎯 Key Features Implemented

- ✅ **Authentication** - Email/password login with Firebase Auth
- ✅ **Real-Time Messaging** - Firestore listeners for instant updates
- ✅ **Offline Support** - Automatic with Firestore persistence
- ✅ **Optimistic Updates** - Messages appear instantly
- ✅ **Message Status** - Sending/sent/delivered/read indicators
- ✅ **Typing Indicators** - See when others are typing
- ✅ **Group Chat Ready** - Backend supports 3+ participants
- ✅ **Local Caching** - SwiftData for offline access

## 🏗️ Architecture

### MVVM Pattern
```
View (SwiftUI) → ViewModel (ObservableObject) → Service Layer → Firebase/SwiftData
```

### Offline-First Design
1. Write to local SwiftData immediately (optimistic)
2. Write to Firestore (queued if offline)
3. Firestore listener updates when confirmed
4. UI stays in sync automatically

### Key Services
- **FirebaseAuthService** - User authentication
- **FirebaseMessageService** - Real-time messaging
- **FirebaseChatService** - Conversation management
- **FirebasePresenceService** - Online status & typing
- **FirebaseNotificationService** - Push notifications

## 📱 Test Users (Seeded Data)

If you ran `firebase/seed_database.py`, you have:

```
alice@test.com / password123
bob@test.com / password123
charlie@test.com / password123
diana@test.com / password123
```

Log in with different users on multiple devices to test real-time messaging!

## 🔧 Development

### Using Firebase Emulators (Recommended)

```bash
cd firebase
firebase emulators:start
```

The app automatically connects to emulators in DEBUG builds.

### Building for Production

1. Comment out emulator config in `FirebaseConfig.swift`
2. Or build in Release mode
3. App connects to production Firebase

## 🧪 Testing Checklist

### Basic Functionality
- [ ] Register new user
- [ ] Login with existing user
- [ ] See conversation list
- [ ] Open conversation
- [ ] Send message
- [ ] Receive message in real-time

### Offline Scenarios
- [ ] Enable Airplane Mode
- [ ] Send messages (queued)
- [ ] Disable Airplane Mode
- [ ] Messages send automatically
- [ ] Receive queued messages

### Multi-Device
- [ ] Login on Device A
- [ ] Login on Device B
- [ ] Send message from A → B
- [ ] See message appear on B instantly
- [ ] Send reply from B → A

## 🐛 Troubleshooting

### Can't Build
- Ensure iOS Deployment Target is **16.0+**
- Check Firebase SDK is added via SPM
- Verify `GoogleService-Info.plist` is in project

### Can't Login
- Check Firebase Console → Authentication is enabled
- Ensure Firestore security rules are deployed
- Try using emulators for debugging

### Messages Not Syncing
- Check internet connection
- Verify Firestore offline persistence is enabled
- Check Firebase Console for errors

## 📚 Documentation

- **Setup Guide**: [XCODE_SETUP.md](./XCODE_SETUP.md)
- **Architecture**: [@docs/systemPatterns.md](./@docs/systemPatterns.md)
- **Firebase Schema**: [firebase/SCHEMA.md](./firebase/SCHEMA.md)
- **Product Requirements**: [@docs/productContext.md](./@docs/productContext.md)

## 🚧 What's Next

### MVP Remaining
- [ ] Image sharing (UI + Storage upload)
- [ ] User search for new conversations
- [ ] Group creation UI
- [ ] Profile editing
- [ ] Push notifications setup

### Post-MVP
- [ ] Voice messages
- [ ] Message reactions
- [ ] Read receipts UI
- [ ] Message search
- [ ] Dark mode support

## 📊 Performance Targets

- **App Launch**: < 2 seconds
- **Message Send**: < 100ms (optimistic UI)
- **Message Delivery**: < 500ms (good network)
- **Scroll Performance**: 60 FPS
- **Memory Usage**: < 100MB base

## 🔒 Security

- **Firebase Auth**: Manages authentication tokens
- **Firestore Rules**: Server-side security (see `firebase/firestore.rules`)
- **Local Storage**: SwiftData encrypted on device
- **Network**: HTTPS only (enforced by iOS)

## 📦 Dependencies

- **FirebaseAuth** (10.0+) - User authentication
- **FirebaseFirestore** (10.0+) - Real-time database
- **FirebaseStorage** (10.0+) - File storage
- **FirebaseMessaging** (10.0+) - Push notifications
- **SwiftData** (iOS 16+) - Local persistence

## 🤝 Contributing

This is a learning/portfolio project. To add features:

1. Read architecture docs in `@docs/`
2. Follow MVVM pattern
3. Add service protocols before implementations
4. Write tests for new services
5. Update this README

## 📝 Notes

- **Minimum iOS**: 16.0 (required for SwiftData)
- **Architecture**: MVVM with offline-first design
- **Backend**: Firebase (Firestore + Cloud Functions)
- **Persistence**: Dual (SwiftData local + Firestore remote)
- **Real-Time**: Firestore snapshot listeners
- **Offline**: Automatic (Firestore SDK + SwiftData)

## 🎓 Learning Resources

- [Firebase iOS Docs](https://firebase.google.com/docs/ios/setup)
- [SwiftData Guide](https://developer.apple.com/documentation/swiftdata)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [MVVM Pattern](https://www.hackingwithswift.com/books/ios-swiftui/introducing-mvvm-into-your-swiftui-project)

---

**Built with**: Swift, SwiftUI, SwiftData, Firebase  
**iOS Version**: 16.0+  
**Created**: October 21, 2025  
**Status**: MVP Ready for Development

Happy Coding! 🚀

