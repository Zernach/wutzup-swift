#!/usr/bin/env bash
set -euo pipefail

main() {
  local bootstrap_root="${MAC_MINI_BOOTSTRAP_ROOT:-$HOME/code/mac-mini-bootstrap}"
  local action="${1:-status}"
  if [[ $# -gt 0 ]]; then shift; fi
  local plan="$bootstrap_root/config/mobile-releases/wutzup-2.0.0.json"
  if [[ ! -f "$bootstrap_root/scripts/mobile-release/release.py" ]]; then
    printf '%s\n' 'Set MAC_MINI_BOOTSTRAP_ROOT to the bootstrap checkout containing the shared release tool.' >&2
    return 1
  fi
  exec python3 "$bootstrap_root/scripts/mobile-release/release.py" "$action" --plan "$plan" "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi
