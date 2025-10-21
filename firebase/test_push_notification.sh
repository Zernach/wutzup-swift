#!/bin/bash
# Test Push Notification Script
# This script tests the push notification system by triggering a test notification

set -e

echo "🧪 Testing Push Notification System"
echo "===================================="
echo ""

# Check if Firebase CLI is logged in
if ! firebase projects:list &>/dev/null; then
    echo "❌ Error: Not logged into Firebase CLI"
    echo "Run: firebase login"
    exit 1
fi

echo "✅ Firebase CLI authenticated"
echo ""

# Get current project
PROJECT_ID=$(firebase use | grep -o 'wutzup-swift' | head -1)
if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: No Firebase project selected"
    echo "Run: firebase use wutzup-swift"
    exit 1
fi

echo "📦 Project: $PROJECT_ID"
echo ""

# Check if functions are deployed
echo "🔍 Checking deployed functions..."
FUNCTIONS=$(firebase functions:list 2>/dev/null | grep "on_message_created" || true)

if [ -z "$FUNCTIONS" ]; then
    echo "❌ Error: on_message_created function not found"
    echo "Deploy functions with: firebase deploy --only functions"
    exit 1
fi

echo "✅ on_message_created function deployed"
echo ""

# Prompt for user ID
echo "📝 To test notifications, you need:"
echo "   1. A user ID from your Firestore users collection"
echo "   2. That user must have logged in and granted notification permission"
echo "   3. That user must have an 'fcmToken' field in Firestore"
echo ""

read -p "Enter user ID to test: " USER_ID

if [ -z "$USER_ID" ]; then
    echo "❌ Error: User ID is required"
    exit 1
fi

echo ""
echo "🚀 Sending test notification to user: $USER_ID"
echo ""

# Get the function URL
FUNCTION_URL=$(firebase functions:config:get | grep -o 'https://.*test_notification' || true)

if [ -z "$FUNCTION_URL" ]; then
    # Construct URL manually
    REGION="us-central1"
    FUNCTION_URL="https://${REGION}-${PROJECT_ID}.cloudfunctions.net/test_notification"
fi

echo "📡 Function URL: $FUNCTION_URL"
echo ""

# Send test request
RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
    -H "Content-Type: application/json" \
    -d "{
        \"userId\": \"$USER_ID\",
        \"title\": \"Test Notification\",
        \"body\": \"This is a test notification from the Wutzup system!\"
    }" || echo "ERROR")

echo "📬 Response: $RESPONSE"
echo ""

if [[ "$RESPONSE" == *"Notification sent"* ]]; then
    echo "✅ SUCCESS! Notification sent"
    echo ""
    echo "📱 Check your device for the notification"
    echo ""
    echo "If you don't receive it, check:"
    echo "  1. User has granted notification permission"
    echo "  2. User has valid 'fcmToken' in Firestore"
    echo "  3. User's device is online"
    echo "  4. APNs key is uploaded to Firebase Console"
    exit 0
elif [[ "$RESPONSE" == *"No FCM token"* ]]; then
    echo "⚠️  User has no FCM token"
    echo ""
    echo "To fix:"
    echo "  1. Log in to the app on the device"
    echo "  2. Grant notification permission when prompted"
    echo "  3. Wait for FCM token to be registered"
    echo "  4. Check Firestore: users/${USER_ID}/fcmToken"
    exit 1
elif [[ "$RESPONSE" == *"User not found"* ]]; then
    echo "❌ User not found in Firestore"
    echo ""
    echo "Check that user ID is correct: $USER_ID"
    exit 1
else
    echo "❌ Failed to send notification"
    echo ""
    echo "Check Cloud Function logs:"
    echo "  firebase functions:log --only test_notification"
    exit 1
fi

