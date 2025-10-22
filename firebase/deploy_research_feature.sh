#!/bin/bash

# Deploy Research Feature to Firebase
# This script deploys the conduct_research cloud function

echo "🔍 Deploying Conduct Research Feature..."
echo ""

# Check if in firebase directory
if [ ! -f "firebase.json" ]; then
    echo "❌ Error: Must run from firebase directory"
    echo "   Run: cd firebase && ./deploy_research_feature.sh"
    exit 1
fi

# Check if OPENAI_API_KEY is set
echo "📋 Checking OpenAI API key configuration..."
OPENAI_KEY=$(firebase functions:config:get openai.api_key 2>/dev/null)

if [ -z "$OPENAI_KEY" ] || [ "$OPENAI_KEY" = "null" ]; then
    echo "⚠️  OpenAI API key not configured!"
    echo ""
    echo "   Set your OpenAI API key with:"
    echo "   firebase functions:config:set openai.api_key=\"sk-YOUR-KEY-HERE\""
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✅ OpenAI API key is configured"
fi

# Install dependencies
echo ""
echo "📦 Installing Python dependencies..."
cd functions
pip install -r requirements.txt
cd ..

# Deploy function
echo ""
echo "🚀 Deploying conduct_research function..."
firebase deploy --only functions:conduct_research

# Check deployment status
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment successful!"
    echo ""
    echo "🔗 Function URL:"
    echo "   https://us-central1-$(firebase use | grep -o '\[.*\]' | tr -d '[]').cloudfunctions.net/conduct_research"
    echo ""
    echo "🧪 Test the function with:"
    echo "   curl -X POST \\"
    echo "     https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/conduct_research \\"
    echo "     -H \"Content-Type: application/json\" \\"
    echo "     -d '{\"prompt\": \"What is SwiftUI?\"}'"
    echo ""
    echo "📱 Next steps:"
    echo "   1. Update FirebaseResearchService.swift with your project ID"
    echo "   2. Build the iOS app in Xcode"
    echo "   3. Test the feature in a conversation"
    echo ""
else
    echo ""
    echo "❌ Deployment failed!"
    echo "   Check the error messages above for details."
    exit 1
fi

