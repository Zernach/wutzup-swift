#!/bin/bash

# Deploy Firebase Cloud Functions with environment variables from .env file
# This script reads your .env file and deploys functions with those variables

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Deploying Cloud Functions with environment variables${NC}"
echo ""

# Check if .env file exists in functions directory
if [ ! -f "functions/.env" ]; then
    echo -e "${RED}Error: functions/.env file not found!${NC}"
    echo ""
    echo "Please create a functions/.env file with your environment variables:"
    echo "OPENAI_API_KEY=sk-your-key-here"
    echo ""
    exit 1
fi

# Load environment variables from .env file
export $(cat functions/.env | grep -v '^#' | xargs)

# Check if OPENAI_API_KEY is set
if [ -z "$OPENAI_API_KEY" ]; then
    echo -e "${RED}Error: OPENAI_API_KEY not found in functions/.env file${NC}"
    echo ""
    echo "Please add to functions/.env:"
    echo "OPENAI_API_KEY=sk-your-key-here"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Found OPENAI_API_KEY${NC}"
echo ""

# The .env file will be loaded by python-dotenv at runtime
echo -e "${YELLOW}Deploying functions (with .env file)...${NC}"
firebase deploy --only functions:generate_response_suggestions,functions:conduct_research,functions:generate_gif,functions:message_context,functions:translate_text --force

echo ""
echo -e "${GREEN}✓ Deployment complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Test AI responses with: bash test_ai_response.sh"
echo "2. Test research function in the iOS app"
echo "3. Test GIF generation in the iOS app"
echo "4. Test message context feature in the iOS app"
echo "5. Test translation feature in the iOS app"

