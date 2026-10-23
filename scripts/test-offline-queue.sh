#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_binary=$(mktemp -t wutzup-queue)
trap 'rm -f "$test_binary"' EXIT
swiftc -parse-as-library Wutzup/Services/Local/OfflineMessageQueue.swift \
  Wutzup/Services/Protocols/MessageService.swift Wutzup/Models/Domain/Message.swift \
  Wutzup/Utilities/DraftManager.swift tests/OfflineQueueTests.swift -o "$test_binary"
"$test_binary"
