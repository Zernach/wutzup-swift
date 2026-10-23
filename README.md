# 💬 WutzUp International
## Real-Time iOS Messaging App
### For International Travlers & Language Learners

<div align="center">

![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0+-green.svg)
![Firebase](https://img.shields.io/badge/Firebase-10.0+-yellow.svg)
![License](https://img.shields.io/badge/License-Private-red.svg)

**A native messaging app built with SwiftUI, the Archlife API and Firebase Auth**

[📱 Features](#-features) • [🚀 Quick Start](#-quick-start) • [🏗️ Architecture](#️-architecture) • [📚 Documentation](#-documentation) • [🧪 Testing](#-testing)

</div>

---

## 🌟 Overview

WutzUp is an iOS messaging app for international travelers and language learners. The SwiftUI client uses the Archlife TypeScript API and private PostgreSQL database, with Firebase Auth for identity and SwiftData for local caching. See [the current backend migration](docs/backend-migration.md) and [verification evidence](docs/backend-verification.md) for the implementation and remaining release checks.

### ✨ Key Highlights

- **⚡ Message synchronization** through bounded API polling
- **🔄 Offline message queue** with stable retry IDs
- **👥 Group chat support** for 3+ participants  
- **📱 Native iOS experience** with SwiftUI
- **🔒 Secure authentication** via Firebase Auth
- **📲 Push notifications** for instant alerts
- **🎯 Executable verification** for API, database and native contracts

---

## 📱 Features

### Core Messaging
- **One-on-one chat** with real-time delivery
- **Group conversations** supporting multiple participants
- **Message persistence** across app restarts
- **Optimistic UI updates** for instant feedback
- **Message status indicators** (sending → sent → delivered → read)
- **Rich text support** with timestamps

### Real-Time Capabilities
- **Live presence** - see who's online/offline
- **Typing indicators** - know when others are composing
- **Read receipts** - track message delivery status
- **Bounded synchronization** with backoff and account-switch cancellation
- **Background message handling** - receive messages when app is closed

### Network Resilience
- **Offline message queue** - messages wait for connection
- **Automatic sync** when connectivity returns
- **Poor network handling** - works on 3G, WiFi, and spotty connections
- **Idempotent sends** that retain the original result on retries
- **Graceful degradation** during network issues

### User Experience
- **Native iOS design** following Human Interface Guidelines
- **Smooth animations** and transitions
- **Accessibility support** with VoiceOver and Dynamic Type
- **Dark mode ready** with system integration
- **Haptic feedback** for enhanced interaction

---

## 🚀 Quick Start

### Prerequisites

- **macOS 14+** (Sonoma or later)
- **Xcode 17+** with iOS 16.0+ SDK
- **Google Account** for Firebase
- **Apple Developer Account** ($99/year for App Store)

### Installation

Use the existing checkout and Xcode project:

```sh
open wutzup.xcodeproj
python3 scripts/check-firebase-auth-only.py
bash scripts/test-archlife-backend.sh
bash build.sh
```

The project already includes Firebase Core/Auth and its existing
`Wutzup/Resources/GoogleService-Info.plist`. Keep that identity project. No
Firebase database, Storage, Messaging or Cloud Functions SDK is needed.

Debug uses `https://api-dev.archlife/api/wutzup`; Release uses
`https://api.archlife.org/api/wutzup`. Select `WUTZUP_API_BASE_URL` for the intended
API environment. Backend namespace initialization and historical import must be
completed in that environment before testing real chat persistence. See
[backend migration](docs/backend-migration.md); local builds do not deploy it.

### First Run

1. **Register a new account** or login
2. **Start a conversation** with another user
3. **Send messages** and see real-time delivery
4. **Test offline mode** by disabling network

---

## 🏗️ Architecture

### Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Frontend** | SwiftUI + Swift 5.9+ | Native iOS UI |
| **Local Storage** | SwiftData | Offline persistence |
| **Backend** | Archlife TypeScript API + private PostgreSQL | Application data and AI operations |
| **Identity** | Firebase Auth | Existing accounts and ID tokens |
| **Media** | Archlife private S3 | Profiles and GIFs |
| **Notifications** | SQL outbox + direct APNs | Push notifications |
| **Architecture** | MVVM | Clean separation of concerns |

### Project Structure

```
Wutzup/
├── App/                    # Application entry & state
├── Models/                 # Domain & SwiftData models
├── Services/              # Archlife API services and Firebase Auth
├── ViewModels/            # MVVM business logic
├── Views/                 # SwiftUI user interface
├── Utilities/            # Helpers & extensions
└── Resources/            # Assets & configuration
```

### Key Components

- **🔐 AuthenticationService** - User login/registration
- **💬 MessageService** - Real-time messaging
- **👥 ChatService** - Conversation management  
- **📡 PresenceService** - Online/typing status
- **🔔 NotificationService** - Push notifications

---

## 📚 Documentation

### 📖 Complete Documentation

| Document | Description |
|----------|-------------|
| **[Backend migration](docs/backend-migration.md)** | Current Archlife data/API ownership |
| **[Backend verification](docs/backend-verification.md)** | Automated evidence and release gates |
| **[Product Requirements](@docs/product-requirements-document.md)** | Complete feature specifications |
| **[Architecture Guide](@docs/architecture.md)** | Technical implementation details |
| **[Setup Instructions](XCODE_SETUP.md)** | Step-by-step Xcode setup |
| **[Project Summary](iOS_PROJECT_SUMMARY.md)** | Complete project overview |
| **[Tech Context](@docs/techContext.md)** | Technology stack details |

### 🎯 Quick References

- **[Active Context](@docs/activeContext.md)** - Current status & next steps
- **[Tasks](@docs/tasks.md)** - Implementation checklist
- **[Progress](@docs/progress.md)** - Development tracking

---

## 🧪 Testing

### Critical Test Scenarios

The app must pass these 7 scenarios before launch:

1. **✅ Real-time chat** - Two devices messaging simultaneously
2. **✅ Offline/online transitions** - Messages queue and sync properly  
3. **✅ Background messaging** - Receive messages when app is closed
4. **✅ Force quit recovery** - Restore state after crashes
5. **✅ Poor network conditions** - Handle 3G, packet loss, airplane mode
6. **✅ Rapid-fire messaging** - Send 20+ messages quickly
7. **✅ Group chat** - 3+ participants in conversation

### Performance Benchmarks

- **Message delivery**: < 500ms average
- **App launch**: < 2 seconds to chat list
- **Scroll performance**: 60 FPS with 1000+ messages
- **Crash-free rate**: 99.9%+
- **Message success rate**: 99.9%

---

## 🔧 Development

### Setup Development Environment

```bash
# Install dependencies
./install.sh

# Start Firebase emulators
firebase emulators:start

# Build project
./build.sh
```

### Code Quality

- **MVVM Architecture** - Clean separation of concerns
- **Protocol-Oriented Design** - Easy testing and mocking
- **Type Safety** - Comprehensive error handling
- **Documentation** - Extensive code comments
- **Testing** - Unit, integration, and UI tests

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📊 Project Status

### ✅ Completed Features

- [x] **Authentication System** - Login/register with Firebase
- [x] **Messaging** - Archlife API persistence and polling (local verification)
- [x] **Offline Support** - Message queue and sync
- [x] **Presence & Typing** - Online status and indicators
- [x] **Push Notifications** - Direct APNs adapter and durable outbox (device delivery pending)
- [x] **Group Chat** - Multi-participant conversations
- [x] **Message Persistence** - Local SwiftData cache

### 🚧 In Progress

- [ ] **Image Sharing** - Archlife private media; live delivery verification pending
- [ ] **User Search** - Find and add contacts
- [ ] **Profile Management** - Edit name and photo
- [ ] **Message Search** - Search conversation history

### 📋 Roadmap

- [ ] **Voice Messages** - Record and send audio
- [ ] **Video Messages** - Record and send video
- [ ] **Location Sharing** - Send current location
- [ ] **Message Reactions** - Emoji responses
- [ ] **End-to-End Encryption** - Enhanced privacy
- [ ] **Multi-Device Support** - Sync across devices

---

## Runtime costs

Application data, media and AI usage are owned by Archlife. The old Firebase
Firestore/Functions/Storage estimates do not describe this implementation. The
backend verification notes record the bounded synthetic AI evaluation cost;
production capacity and usage costs still require measurement.

---

## 🎓 Learning Resources

### Identity documentation
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [Firebase Authentication](https://firebase.google.com/docs/auth)

### Swift & SwiftUI
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [SwiftData Guide](https://developer.apple.com/documentation/swiftdata)
- [Combine Framework](https://developer.apple.com/documentation/combine)

### Tools & Resources
- [Firebase Console](https://console.firebase.google.com)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- [Xcode Documentation](https://developer.apple.com/xcode)

---

## 🤝 Support

### Getting Help

- **📖 Documentation** - Check the `@docs/` directory
- **🐛 Issues** - Report bugs via GitHub Issues
- **💬 Discussions** - Ask questions in GitHub Discussions
- **📧 Contact** - Reach out for support

### Community

- **⭐ Star** this repository if you find it helpful
- **🍴 Fork** to contribute improvements
- **📢 Share** with other iOS developers
- **💡 Suggest** new features via Issues

---

## 📄 License

This project is private and intended for portfolio/educational purposes. All rights reserved.

---

## 🙏 Acknowledgments

- **Firebase Team** - For authentication
- **Apple** - For SwiftUI and SwiftData frameworks  
- **SwiftUI Community** - For patterns and best practices
- **Open Source Contributors** - For inspiration and tools

---

<div align="center">

**Built with ❤️ using SwiftUI, Archlife and Firebase Auth**

[⬆ Back to Top](#-wutzup---real-time-ios-messaging-app)

</div>
