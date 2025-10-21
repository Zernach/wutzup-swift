# Wutzup iOS - Xcode Project Setup Guide

This guide walks you through creating the Xcode project and integrating all the Swift source files.

## Prerequisites

- macOS 14.0+ (Sonoma or later)
- Xcode 15.0+
- Swift 5.9+
- Firebase project already set up (see firebase/README.md)

## Step 1: Create New Xcode Project

1. Open Xcode
2. Click **File → New → Project**
3. Select **iOS** → **App**
4. Click **Next**

### Project Settings:
- **Product Name**: `Wutzup`
- **Team**: Select your Apple Developer account
- **Organization Identifier**: `com.yourcompany` (e.g., `org.archlife`)
- **Bundle Identifier**: Will be auto-generated (e.g., `org.archlife.wutzup`)
- **Interface**: **SwiftUI**
- **Language**: **Swift**
- **Storage**: **None** (we're using SwiftData manually)
- **Include Tests**: ✅ Check both Unit Tests and UI Tests

4. Click **Next** and save the project in `/Users/zernach/code/gauntlet/wutzup-swift/`

## Step 2: Configure Project Settings

### 2.1 Set Minimum Deployment Target

1. Select the project in the navigator
2. Select the **Wutzup** target
3. Under **General** tab:
   - **iOS Deployment Target**: Set to **16.0** (required for SwiftData)

### 2.2 Add Capabilities

1. Select the **Wutzup** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability** and add:
   - **Push Notifications**
   - **Background Modes**
     - Check: **Background fetch**
     - Check: **Remote notifications**

## Step 3: Add Firebase SDK via Swift Package Manager

1. In Xcode, go to **File → Add Package Dependencies**
2. Enter the Firebase iOS SDK URL:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
3. Select **Up to Next Major Version**: `10.0.0`
4. Click **Add Package**
5. Select the following products:
   - ✅ **FirebaseAuth**
   - ✅ **FirebaseFirestore**
   - ✅ **FirebaseStorage**
   - ✅ **FirebaseMessaging**
6. Click **Add Package**

## Step 4: Download GoogleService-Info.plist

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your **Wutzup** project
3. Click the gear icon → **Project Settings**
4. Scroll down to **Your apps**
5. If iOS app doesn't exist:
   - Click **Add app** → **iOS**
   - Enter your Bundle ID (e.g., `org.archlife.wutzup`)
   - Click **Register app**
6. Download **GoogleService-Info.plist**
7. Drag the file into your Xcode project:
   - Place it in the `Wutzup/Resources/` folder
   - ✅ Ensure **"Copy items if needed"** is checked
   - ✅ Ensure **"Add to targets: Wutzup"** is checked

## Step 5: Import Swift Source Files

The Swift source files are already created in the `Wutzup/` directory. You need to add them to your Xcode project:

### 5.1 Remove Default Files

1. Delete the default `ContentView.swift` and `WutzupApp.swift` from Xcode (move to trash)

### 5.2 Add Source Folders

1. Right-click on the **Wutzup** group in Xcode
2. Select **Add Files to "Wutzup"...**
3. Navigate to the `Wutzup/` directory (the one with all the source files)
4. Select the following folders:
   - `App/`
   - `Models/`
   - `Services/`
   - `ViewModels/`
   - `Views/`
   - `Utilities/`
5. **Important Options**:
   - ✅ **"Create groups"** (NOT "Create folder references")
   - ✅ **"Copy items if needed"** (leave unchecked since files are already in project)
   - ✅ **"Add to targets: Wutzup"**
6. Click **Add**

### 5.3 Add Info.plist

1. Right-click on **Wutzup/Resources/** folder
2. Select **Add Files to "Wutzup"...**
3. Navigate to `Wutzup/Resources/Info.plist`
4. Click **Add**

### 5.4 Set Info.plist in Build Settings

1. Select the **Wutzup** target
2. Go to **Build Settings** tab
3. Search for **"Info.plist"**
4. Under **Packaging** → **Info.plist File**:
   - Set to: `Wutzup/Resources/Info.plist`

## Step 6: Fix Build Errors (If Any)

After adding files, you might see some import errors. Let's fix them:

### 6.1 Check Firebase Imports

Make sure all files that use Firebase have proper imports:
- `import FirebaseAuth`
- `import FirebaseFirestore`
- `import FirebaseStorage`
- `import FirebaseMessaging`

### 6.2 Build the Project

1. Press **Cmd + B** to build
2. If there are errors, check the navigator for details
3. Common issues:
   - Missing Firebase imports → Add them
   - SwiftData @Model errors → Make sure iOS target is 16.0+

## Step 7: Configure Firebase for Debug (Optional)

To use Firebase Emulators during development:

### 7.1 Start Firebase Emulators

In Terminal:
```bash
cd /Users/zernach/code/gauntlet/wutzup-swift/firebase
firebase emulators:start
```

### 7.2 App Will Auto-Connect

The app automatically connects to emulators in DEBUG builds (see `FirebaseConfig.swift`).

## Step 8: Upload APNs Key to Firebase (For Push Notifications)

### 8.1 Create APNs Key

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Keys** → **+** (Create a new key)
4. Name it: `Wutzup APNs Key`
5. Check **Apple Push Notifications service (APNs)**
6. Click **Continue** → **Register**
7. Download the `.p8` file
8. **Important**: Note the **Key ID**

### 8.2 Upload to Firebase

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Click gear icon → **Project Settings**
4. Go to **Cloud Messaging** tab
5. Under **Apple app configuration**:
   - Click **Upload** next to APNs Authentication Key
   - Upload your `.p8` file
   - Enter your **Key ID**
   - Enter your **Team ID** (found in Apple Developer Portal)
6. Click **Upload**

## Step 9: Run the App

1. Select a simulator or connected device (iOS 16.0+)
2. Press **Cmd + R** to run
3. The app should launch and show the login screen

### Expected Behavior:

- ✅ Login screen appears
- ✅ Can register new user (creates in Firebase)
- ✅ Can log in with existing user
- ✅ After login, see empty chat list
- ✅ No crashes or errors

## Step 10: Test with Seeded Data

If you ran the Firebase seeding script (`seed_database.py`), you should have test users:

### Test Users:
```
Email: alice@test.com
Password: password123

Email: bob@test.com
Password: password123

Email: charlie@test.com
Password: password123

Email: diana@test.com
Password: password123
```

### Testing:
1. Log in as Alice on Simulator
2. See existing conversations with Bob, Charlie, and Group
3. Tap a conversation
4. See existing messages
5. Send a new message
6. Log in as Bob on a physical device (or second simulator)
7. Verify real-time message delivery

## Troubleshooting

### Build Errors

**Error**: `Cannot find 'FirebaseApp' in scope`
- **Fix**: Make sure Firebase packages are added via SPM
- Go to **File → Add Package Dependencies** and re-add Firebase SDK

**Error**: `SwiftData @Model not available`
- **Fix**: Ensure iOS Deployment Target is **16.0+**
- Check **Build Settings → iOS Deployment Target**

**Error**: `GoogleService-Info.plist not found`
- **Fix**: Ensure the file is in the project and added to target
- Check file inspector (right panel) and ensure target membership is checked

### Runtime Errors

**Error**: `Firebase not configured`
- **Fix**: Ensure `FirebaseApp.configure()` is called in `WutzupApp.swift`
- Check that `GoogleService-Info.plist` is in the bundle

**Error**: `Firestore permission denied`
- **Fix**: Check Firebase security rules
- In DEBUG mode, use emulators (no auth required)
- In production, ensure user is authenticated

**Error**: Messages not syncing
- **Fix**: Check network connection
- Check Firebase Console for Firestore errors
- Ensure offline persistence is enabled

### Emulator Issues

**Error**: Can't connect to emulators
- **Fix**: Ensure emulators are running: `firebase emulators:start`
- Check `FirebaseConfig.swift` has correct host/port
- Emulators only work in DEBUG builds

## Next Steps

### Development Workflow

1. **Use Emulators for Development**
   ```bash
   cd firebase
   firebase emulators:start
   ```

2. **Run App in Debug Mode**
   - Automatically connects to emulators
   - No production data affected

3. **Test on Real Device**
   - Switch to Release build or comment out emulator config
   - Uses production Firebase

### Adding Features

- **Images**: Implement image picker and Firebase Storage upload
- **Groups**: UI for creating groups (backend logic already exists)
- **Presence**: Online/offline indicators (service already implemented)
- **Search**: Add user search to create new conversations

### Deployment

When ready for TestFlight/App Store:

1. **Archive the app**: Product → Archive
2. **Validate**: Use Xcode's validation
3. **Upload**: Distribute → App Store Connect
4. **TestFlight**: Invite testers via App Store Connect

## Project Structure

```
Wutzup/
├── App/
│   ├── WutzupApp.swift          # Entry point + Firebase config
│   ├── AppState.swift            # Global app state
│   └── ContentView.swift         # Root view router
├── Models/
│   ├── Domain/                   # Domain models (Codable)
│   │   ├── User.swift
│   │   ├── Message.swift
│   │   └── Conversation.swift
│   └── SwiftData/                # Local persistence models
│       ├── UserModel.swift
│       ├── MessageModel.swift
│       └── ConversationModel.swift
├── Services/
│   ├── Protocols/                # Service interfaces
│   └── Firebase/                 # Firebase implementations
├── ViewModels/
│   ├── AuthenticationViewModel.swift
│   ├── ChatListViewModel.swift
│   └── ConversationViewModel.swift
├── Views/
│   ├── Authentication/           # Login/Register
│   ├── ChatList/                 # Conversation list
│   ├── Conversation/             # Chat interface
│   └── Components/               # Reusable components
├── Utilities/
│   ├── FirebaseConfig.swift      # Firebase configuration
│   ├── Constants.swift           # App constants
│   └── DateFormatter+Helpers.swift
└── Resources/
    ├── Info.plist
    └── GoogleService-Info.plist  # From Firebase Console
```

## Resources

- **Firebase iOS Guide**: https://firebase.google.com/docs/ios/setup
- **SwiftData Documentation**: https://developer.apple.com/documentation/swiftdata
- **SwiftUI Documentation**: https://developer.apple.com/documentation/swiftui
- **Project Documentation**: See `@docs/` folder for architecture and patterns

## Support

If you encounter issues:
1. Check this README's Troubleshooting section
2. Check Firebase Console for errors
3. Review `@docs/systemPatterns.md` for architecture details
4. Check Firebase Emulator logs: `firebase emulators:start --debug`

---

**Created**: October 21, 2025  
**Last Updated**: October 21, 2025  
**Version**: 1.0.0

