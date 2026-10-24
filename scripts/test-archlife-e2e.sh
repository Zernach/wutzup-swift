#!/usr/bin/env bash
# Run from any directory; all test infrastructure and the simulator are disposable.
set -euo pipefail
native_root=$(cd "$(dirname "$0")/.." && pwd)
cloud_root=${WUTZUP_CLOUD_ROOT:-/Users/zernach/code/archlife-apps-runtime/services/typescript-cloud}
test -f "$cloud_root/scripts/run-wutzup-e2e.mjs" || { echo 'Set WUTZUP_CLOUD_ROOT to the TypeScript cloud checkout' >&2; exit 1; }
python3 "$native_root/scripts/check-firebase-auth-only.py"
bash "$native_root/scripts/test-archlife-backend.sh"
bash "$native_root/scripts/test-offline-queue.sh"
python3 "$native_root/scripts/test-offline-queue-mutations.py"
cd "$cloud_root"
node scripts/run-wutzup-e2e.mjs --native "$native_root" "$@"
