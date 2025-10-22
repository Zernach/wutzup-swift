#!/bin/bash

# Test script for AI response generation Cloud Function
# This script tests the generate_response_suggestions endpoint

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="wutzup-app-c9887"
REGION="us-central1"
FUNCTION_URL="https://${REGION}-${PROJECT_ID}.cloudfunctions.net/generate_response_suggestions"

echo -e "${YELLOW}Testing AI Response Generation Cloud Function${NC}"
echo "Function URL: $FUNCTION_URL"
echo ""

# Test 1: Simple conversation
echo -e "${YELLOW}Test 1: Simple coffee invitation${NC}"
RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "conversation_history": [
      {
        "sender_id": "user1",
        "sender_name": "Alice",
        "content": "Want to grab coffee tomorrow?",
        "timestamp": "2025-10-22T10:00:00Z"
      }
    ]
  }')

echo "Response: $RESPONSE"
echo ""

# Check if response contains expected fields
if echo "$RESPONSE" | jq -e '.positive_response and .negative_response' > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Test 1 PASSED: Response has both positive and negative suggestions${NC}"
else
  echo -e "${RED}✗ Test 1 FAILED: Response missing required fields${NC}"
fi
echo ""

# Test 2: Multi-message conversation
echo -e "${YELLOW}Test 2: Multi-message conversation${NC}"
RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "conversation_history": [
      {
        "sender_id": "user1",
        "sender_name": "Bob",
        "content": "Hey! How was your weekend?",
        "timestamp": "2025-10-22T09:00:00Z"
      },
      {
        "sender_id": "user2",
        "sender_name": "You",
        "content": "Pretty good! Went hiking on Saturday.",
        "timestamp": "2025-10-22T09:05:00Z"
      },
      {
        "sender_id": "user1",
        "sender_name": "Bob",
        "content": "Nice! Want to join our hiking group next weekend?",
        "timestamp": "2025-10-22T09:10:00Z"
      }
    ]
  }')

echo "Response: $RESPONSE"
echo ""

if echo "$RESPONSE" | jq -e '.positive_response and .negative_response' > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Test 2 PASSED: Multi-message conversation handled${NC}"
else
  echo -e "${RED}✗ Test 2 FAILED: Multi-message conversation failed${NC}"
fi
echo ""

# Test 3: With user personality
echo -e "${YELLOW}Test 3: Conversation with user personality${NC}"
RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "conversation_history": [
      {
        "sender_id": "user1",
        "sender_name": "Sarah",
        "content": "Are you coming to the party tonight?",
        "timestamp": "2025-10-22T15:00:00Z"
      }
    ],
    "user_personality": "I am introverted and prefer quiet gatherings. I like being polite but honest."
  }')

echo "Response: $RESPONSE"
echo ""

if echo "$RESPONSE" | jq -e '.positive_response and .negative_response' > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Test 3 PASSED: Personality context handled${NC}"
else
  echo -e "${RED}✗ Test 3 FAILED: Personality context failed${NC}"
fi
echo ""

# Test 4: Error handling - missing conversation history
echo -e "${YELLOW}Test 4: Error handling - missing conversation history${NC}"
RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d '{}')

echo "Response: $RESPONSE"
echo ""

if echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Test 4 PASSED: Error handling works${NC}"
else
  echo -e "${RED}✗ Test 4 FAILED: Error not returned for invalid request${NC}"
fi
echo ""

# Summary
echo -e "${YELLOW}===========================================${NC}"
echo -e "${YELLOW}Test Summary${NC}"
echo -e "${YELLOW}===========================================${NC}"
echo ""
echo "Function URL: $FUNCTION_URL"
echo "All tests completed. Check results above."
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "1. Verify all tests passed"
echo "2. Test in iOS app with real conversations"
echo "3. Monitor OpenAI usage in OpenAI dashboard"
echo "4. Set up billing alerts if needed"

