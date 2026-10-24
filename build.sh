#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
# A separate cache avoids stale absolute paths in the historical `build/` tree.
xcodebuild -project wutzup.xcodeproj -scheme wutzup \
  -configuration "${WUTZUP_BUILD_CONFIGURATION:-Debug}" -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "${WUTZUP_DERIVED_DATA_PATH:-build-archlife}" \
  CODE_SIGNING_ALLOWED=NO build
