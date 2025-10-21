# Swift Package Dependencies

This document lists all external dependencies for the Wutzup iOS app.

## Firebase iOS SDK

**Repository**: https://github.com/firebase/firebase-ios-sdk  
**Version**: 10.0.0 or later  
**License**: Apache 2.0

### Required Products

Add these products when importing the Firebase iOS SDK:

1. **FirebaseAuth**
   - Purpose: User authentication (email/password)
   - Used in: `FirebaseAuthService`
   
2. **FirebaseFirestore**
   - Purpose: Real-time database with offline support
   - Used in: `FirebaseMessageService`, `FirebaseChatService`, `FirebasePresenceService`
   
3. **FirebaseStorage**
   - Purpose: File and image storage
   - Used in: Image upload/download (future feature)
   
4. **FirebaseMessaging**
   - Purpose: Push notifications via FCM
   - Used in: `FirebaseNotificationService`

## How to Add Dependencies

### Via Xcode (Recommended)

1. Open your Xcode project
2. Go to **File → Add Package Dependencies**
3. Enter the URL: `https://github.com/firebase/firebase-ios-sdk`
4. Select version: **Up to Next Major Version** `10.0.0`
5. Click **Add Package**
6. Select the 4 products listed above
7. Click **Add Package**

### Via Swift Package Manager (Manual)

If you're using Package.swift for a Swift package:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Wutzup",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk",
            from: "10.0.0"
        )
    ],
    targets: [
        .target(
            name: "Wutzup",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
            ]
        )
    ]
)
```

## Optional Dependencies (Future)

These are not required for MVP but may be added later:

### Kingfisher (Image Caching)
**Repository**: https://github.com/onevcat/Kingfisher  
**Purpose**: Efficient image downloading and caching  
**When to add**: When implementing image messages

### Firebase Analytics (Optional)
**Product**: `FirebaseAnalytics`  
**Purpose**: User analytics and crash reporting  
**When to add**: Post-MVP for tracking

### Firebase Performance (Optional)
**Product**: `FirebasePerformance`  
**Purpose**: Performance monitoring  
**When to add**: Post-MVP for optimization

## Native iOS Frameworks Used

These are built into iOS and don't need to be added:

- **SwiftUI** - UI framework
- **SwiftData** - Local persistence (iOS 16+)
- **Combine** - Reactive programming
- **UserNotifications** - Local and remote notifications
- **Foundation** - Core utilities

## Minimum iOS Version

**iOS 16.0** is required for SwiftData support.

If you need to support older iOS versions:
- Use Core Data instead of SwiftData
- Minimum iOS version can be lowered to 15.0

## Dependency Updates

To update Firebase SDK:

1. In Xcode, go to **File → Packages → Update to Latest Package Versions**
2. Or right-click the package in Project Navigator → **Update Package**

## Troubleshooting

### Build Errors After Adding Packages

If you see build errors after adding Firebase:
1. Clean build folder: **Product → Clean Build Folder** (Cmd + Shift + K)
2. Restart Xcode
3. Rebuild: **Product → Build** (Cmd + B)

### Missing Firebase Imports

If you see "Cannot find 'Firebase' in scope":
1. Ensure packages are added to your target
2. Check Project Navigator → Package Dependencies
3. Verify imports at top of Swift files:
   ```swift
   import FirebaseAuth
   import FirebaseFirestore
   import FirebaseStorage
   import FirebaseMessaging
   ```

### Version Conflicts

If you have version conflicts:
1. Use consistent version rules: "Up to Next Major Version"
2. Avoid mixing "Exact Version" and "Up to Next Major"
3. Check Package.resolved file for actual versions used

## License Compliance

All dependencies use permissive licenses:
- **Firebase iOS SDK**: Apache License 2.0
- **SwiftData**: Apple (built-in, no separate license)

Make sure to comply with Apache 2.0 license requirements:
- Include copyright notice in your app
- Include copy of Apache 2.0 license if distributing

---

**Last Updated**: October 21, 2025  
**Firebase SDK Version**: 10.0.0+  
**Swift Version**: 5.9+  
**iOS Version**: 16.0+

