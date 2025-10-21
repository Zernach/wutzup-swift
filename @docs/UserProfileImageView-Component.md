# UserProfileImageView Component

## Overview

`UserProfileImageView` is a reusable SwiftUI component that displays a user's profile image with real-time online status indicators. This component is used throughout the app wherever user profile images are displayed.

## Features

- ✅ **Profile Image Display**: Shows user profile image (from URL) or generates initials placeholder
- ✅ **Online Status Indicator**: Real-time green (#72fa41) or red dot to show online/offline status
- ✅ **Flexible Sizing**: Accepts custom size parameter for different use cases
- ✅ **Optional Status**: Can hide online status indicator when not needed
- ✅ **Real-time Updates**: Uses Firebase Presence Service for live status updates
- ✅ **Automatic Cleanup**: Properly cancels observation tasks when view disappears

## Usage

### Basic Usage with Online Status

```swift
UserProfileImageView(
    user: someUser,
    size: 50,
    showOnlineStatus: true,
    presenceService: appState.presenceService
)
```

### Without Online Status

```swift
UserProfileImageView(
    user: someUser,
    size: 100,
    showOnlineStatus: false,
    presenceService: nil
)
```

### Different Sizes

```swift
// Small (navigation bar, inline text)
UserProfileImageView(user: user, size: 30, showOnlineStatus: true, presenceService: presenceService)

// Medium (list items, default)
UserProfileImageView(user: user, size: 50, showOnlineStatus: true, presenceService: presenceService)

// Large (profile screens)
UserProfileImageView(user: user, size: 100, showOnlineStatus: true, presenceService: presenceService)
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `user` | `User?` | Required | The user whose profile to display |
| `size` | `CGFloat` | `AppConstants.Sizes.profileImageSize` (40) | Diameter of the circular profile image |
| `showOnlineStatus` | `Bool` | `true` | Whether to show online/offline indicator |
| `presenceService` | `PresenceService?` | `nil` | Service to observe user presence (required if `showOnlineStatus` is `true`) |

## Online Status Indicator

### Colors

- **Online**: `#72fa41` (bright green)
- **Offline**: `Color.red` (iOS system red)

### Position & Size

- **Position**: Bottom-right of the profile image
- **Size**: 28% of the profile image diameter
- **Border**: White stroke (6% of profile image diameter) for contrast against backgrounds

## Integration Points

This component is used in the following locations:

1. **ConversationRowView** - Shows online status of conversation participants
2. **NewChatView** - Shows online status when selecting users to chat with
3. **AccountView** - Shows current user's profile with online status
4. **MessageBubbleView** - (Optional) Can be used for group chat messages

## Architecture

### Real-time Presence

The component uses Firebase Firestore's real-time listeners to observe user presence:

```swift
private func observePresence() async {
    guard let userId = user?.id, 
          let presenceService = presenceService 
    else { return }
    
    presenceTask = Task {
        for await presence in presenceService.observePresence(userId: userId) {
            await MainActor.run {
                isOnline = (presence.status == .online)
            }
        }
    }
}
```

### Automatic Cleanup

The component automatically cancels observation tasks when:
- The view disappears (`onDisappear`)
- The user changes (`task(id: user?.id)`)

## Implementation Details

### Profile Image Display

1. **Remote Image**: If `user.profileImageUrl` is set, uses `AsyncImage` to load from URL
2. **Initials Placeholder**: If no image, shows user's initials in a circular background
3. **Fallback Icon**: If no user or display name, shows default person icon

### Initials Generation

```swift
private func initials(from name: String) -> String {
    let components = name.split(separator: " ")
    if components.count >= 2 {
        // First + Last initial (e.g., "JD")
        return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
    } else if let first = components.first {
        // Single initial (e.g., "J")
        return String(first.prefix(1)).uppercased()
    }
    return "?"
}
```

## User Caching Strategy

To efficiently show online status for all users in the chat list, `ChatListViewModel` implements user caching:

```swift
// In ChatListViewModel
private var userCache: [String: User] = [:]

func getUser(byId userId: String) -> User? {
    return userCache[userId]
}

func cacheUser(_ user: User) {
    userCache[user.id] = user
}
```

When conversations are fetched, the view model automatically:
1. Extracts all unique participant IDs
2. Fetches user data from `UserService`
3. Caches users for quick lookup

## Example: ChatListView Integration

```swift
private var conversationListView: some View {
    List {
        ForEach(viewModel.conversations) { conversation in
            NavigationLink(value: conversation) {
                ConversationRowView(
                    conversation: conversation,
                    currentUserId: appState.currentUser?.id ?? "",
                    otherUser: otherUser(for: conversation),  // From cache
                    presenceService: appState.presenceService
                )
            }
        }
    }
}

private func otherUser(for conversation: Conversation) -> User? {
    guard !conversation.isGroup else { return nil }
    
    let currentUserId = appState.currentUser?.id ?? ""
    let otherParticipantId = conversation.participantIds.first { $0 != currentUserId }
    
    if let userId = otherParticipantId {
        return viewModel.getUser(byId: userId)  // Get from cache
    }
    
    return nil
}
```

## Performance Considerations

### Efficient Updates

- Each `UserProfileImageView` only observes one user's presence
- Firestore listeners are automatically cleaned up when views disappear
- User data is cached at the ViewModel level to avoid redundant fetches

### Memory Management

- Uses `@State` for local component state
- Properly cancels async tasks in `onDisappear`
- Weak references used where appropriate

## Testing

### Preview Providers

The component includes comprehensive SwiftUI previews:

- **Online User**: Green status indicator
- **Offline User**: Red status indicator
- **Various Sizes**: 30pt, 50pt, 80pt, 120pt
- **Without Status**: No indicator shown

### Preview Mock Service

```swift
private class PreviewPresenceService: PresenceService {
    let isOnline: Bool
    
    init(isOnline: Bool) {
        self.isOnline = isOnline
    }
    
    func observePresence(userId: String) -> AsyncStream<Presence> {
        AsyncStream { continuation in
            let presence = Presence(
                userId: userId,
                status: isOnline ? .online : .offline,
                lastSeen: Date(),
                typing: [:]
            )
            continuation.yield(presence)
            continuation.finish()
        }
    }
    // ... other protocol methods
}
```

## Future Enhancements

Possible improvements for future versions:

1. **Image Caching**: Integrate Kingfisher or SDWebImage for better remote image handling
2. **Custom Status Colors**: Allow passing custom colors for different status types
3. **Status Types**: Support more than online/offline (e.g., away, busy, invisible)
4. **Animations**: Pulse animation for the status indicator
5. **Accessibility**: Improve VoiceOver support with status announcements
6. **Offline Timestamp**: Show "Last seen X minutes ago" on tap

## Files Modified

This implementation involved changes to the following files:

1. **Created**: `wutzup/Views/Components/UserProfileImageView.swift` (new component)
2. **Updated**: `wutzup/Views/ChatList/ConversationRowView.swift` (uses component)
3. **Updated**: `wutzup/Views/NewConversation/NewChatView.swift` (uses component)
4. **Updated**: `wutzup/Views/Account/AccountView.swift` (uses component)
5. **Updated**: `wutzup/Views/ChatList/ChatListView.swift` (passes presence service)
6. **Updated**: `wutzup/ViewModels/ChatListViewModel.swift` (user caching)
7. **Updated**: `wutzup/App/AppState.swift` (passes userService to viewModel)

## Migration Notes

If you're updating existing code to use this component:

### Before
```swift
Image(systemName: "person.circle.fill")
    .resizable()
    .frame(width: 50, height: 50)
```

### After
```swift
UserProfileImageView(
    user: user,
    size: 50,
    showOnlineStatus: true,
    presenceService: presenceService
)
```

---

**Created**: October 21, 2025  
**Last Updated**: October 21, 2025  
**Component Version**: 1.0

