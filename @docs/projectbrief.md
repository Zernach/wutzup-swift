# Project Brief: Wutzup

## Project Name
**Wutzup** - Real-Time Messaging iOS Application

## Project Type
Native iOS Application (Swift + SwiftUI)

## Core Objective
Build a production-ready, real-time messaging application for iOS that enables reliable one-on-one and group conversations with offline-first architecture and seamless network handling.

## Problem Statement
Users need a reliable messaging app that:
- Delivers messages instantly when online
- Works seamlessly when offline
- Never loses messages under any circumstance
- Handles poor network conditions gracefully
- Provides real-time feedback on message status

## Success Criteria
The project is successful when:
1. ✅ Users can send/receive messages in real-time (< 1 second delivery)
2. ✅ All messages persist locally and survive app crashes
3. ✅ Offline messages queue and sync automatically on reconnect
4. ✅ Users see online/offline status and typing indicators
5. ✅ Group chat supports 3+ users with proper message tracking
6. ✅ Push notifications work in foreground
7. ✅ All 7 critical test scenarios pass without data loss

## Scope

### In Scope (MVP)
- User authentication (register, login, logout)
- One-on-one text messaging
- Group chat (3+ participants)
- Real-time message delivery via WebSocket
- Message persistence with Core Data
- Offline message queue with auto-sync
- Optimistic UI updates
- Online/offline presence indicators
- Typing indicators
- Read receipts
- Message timestamps and status tracking
- Basic image sharing
- Push notifications (foreground)
- User profiles with display names and pictures

### Out of Scope (Post-MVP)
- Voice/video calling
- End-to-end encryption
- Message editing/deletion
- Message reactions
- File attachments (non-image)
- Message search
- Multi-device support
- Desktop applications
- Public channels

## Timeline
**Target**: 8-10 weeks (single developer) or 6-8 weeks (2 developers)

### Key Milestones
- **Week 2**: Authentication and basic UI complete
- **Week 4**: Core one-on-one messaging working
- **Week 5**: Offline support and reliability features
- **Week 6**: Real-time features (presence, typing, read receipts)
- **Week 7**: Group chat functionality
- **Week 8**: Testing, polish, and deployment preparation

## Technical Approach
- **Frontend**: Swift, SwiftUI, iOS 15+
- **Backend**: Firebase (Firestore, Cloud Functions, Auth, FCM)
- **Database**: Firebase Firestore (real-time, NoSQL)
- **Real-Time**: Firestore real-time listeners (native)
- **Local Storage**: SwiftData (iOS 16+)
- **Networking**: URLSession + Firebase SDK
- **Architecture**: MVVM with offline-first principles (Firestore offline persistence)

## Constraints
- iOS 16.0+ minimum deployment target (required for SwiftData)
- Native Swift development only (no cross-platform frameworks)
- Must handle poor network conditions (3G, packet loss, intermittent)
- Must pass all test scenarios before launch
- Zero tolerance for message loss
- Firebase free tier limits (Spark plan) or paid plan (Blaze)

## Stakeholders
- **Developer(s)**: Implementation and testing
- **End Users**: iOS users who need reliable messaging
- **Project Owner**: Product direction and requirements

## Risks
1. **High Risk**: Real-time synchronization complexity, offline state management
2. **Medium Risk**: Push notification setup, group chat delivery tracking
3. **Low Risk**: Basic UI implementation, image handling

## Dependencies
- Apple Developer Account (for App Store distribution)
- Firebase project (free Spark plan or paid Blaze plan)
- Firebase CLI (for Cloud Functions deployment)
- Google Cloud account (linked to Firebase)
- APNs certificate/key (uploaded to Firebase for FCM)

## Definition of Done
The MVP is complete when:
- All critical features work reliably across devices
- All 7 test scenarios pass consistently
- No data loss occurs under any tested condition
- Performance meets benchmarks (< 1s delivery, 60 FPS scroll)
- Zero critical bugs remain
- App ready for TestFlight distribution

---

**Project Start Date**: October 21, 2025  
**Status**: Planning Phase Complete

