#!/bin/bash

# Deploy Profile Image Upload Feature
# This script deploys only the Storage rules needed for profile image uploads

set -e  # Exit on error

echo "🚀 Deploying Profile Image Upload Feature..."
echo ""

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Error: Firebase CLI is not installed"
    echo "Install it with: npm install -g firebase-tools"
    exit 1
fi

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "📁 Current directory: $SCRIPT_DIR"
echo ""

# Check if user is logged in
echo "🔐 Checking Firebase authentication..."
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not logged in to Firebase"
    echo "Please run: firebase login"
    exit 1
fi

echo "✅ Authenticated"
echo ""

# Deploy Storage rules only
echo "📤 Deploying Storage rules..."
firebase deploy --only storage

echo ""
echo "✅ Profile Image Upload Feature Deployed!"
echo ""
echo "📝 Summary:"
echo "  - Updated storage.rules to allow profile image uploads"
echo "  - Profile images are stored at: users/{userId}/profile/{fileName}"
echo "  - Users can only upload to their own profile folder"
echo "  - Profile images are publicly readable"
echo ""
echo "🔧 Frontend changes:"
echo "  - Updated AccountView with PhotosPicker"
echo "  - Added image compression (max 1MB)"
echo "  - Added upload progress indicator"
echo "  - Profile image updates automatically on upload"
echo ""
echo "✨ Ready to test! Build and run the iOS app."

