#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_binary=$(mktemp -t wutzup-transport)
trap 'rm -f "$test_binary"' EXIT
swiftc -DDEBUG Wutzup/Services/WutzupRequestTransport.swift \
  Wutzup/Services/WutzupResearchText.swift \
  Wutzup/Services/WutzupWire.swift \
  Wutzup/Services/WutzupMediaResponse.swift \
  Wutzup/Models/Domain/UserType.swift \
  Wutzup/Models/Domain/Conversation.swift \
  Wutzup/Models/Domain/Message.swift \
  Wutzup/Services/Protocols/PresenceService.swift \
  Wutzup/Services/Protocols/AIService.swift \
  tests/ArchlifeTransportTests.swift -o "$test_binary"
"$test_binary" tests/fixtures/archlife-api.json
