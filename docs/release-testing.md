# Release verification

Run the native application and the TypeScript port against disposable resources.
The joint release gate lives in the private TypeScript repository, which can
check out this public native repository without introducing a personal token.
Neither a build nor the original standalone wire tests substitute for this gate.

## Commands

Prerequisites: Node 24.13.1, Yarn 1.22.22, Java 21+, Docker, Xcode with an installed
iOS simulator runtime, XcodeGen, and the existing local-only DNS alias
`api-dev.archlife -> 127.0.0.1`. Install cloud dependencies with
`yarn install --frozen-lockfile`. Do not run the managed runtime or reset any
existing simulator to prepare these tests.

From the native checkout:

```sh
bash scripts/test-archlife-e2e.sh
```

Set `WUTZUP_CLOUD_ROOT` when the TypeScript checkout is elsewhere. The wrapper
runs the Firebase boundary guard, Debug/Release transport contracts, queue/draft
regressions/mutations and the actual app UI suite. The default uses real Docker PostgreSQL,
Hasura and MinIO. It takes a few minutes; the first Swift package build is slower.

The full local release command runs build/types/format/parity, unit/SQL/BDD,
mutations, Auth, dependency security, API E2E, the native workflow and Release build:

```sh
yarn test:wutzup:release /absolute/path/to/wutzup-swift
```

Run it from TypeScript cloud. Individual gates remain available:

```sh
yarn test:wutzup:e2e
yarn test:wutzup:swift:e2e /absolute/path/to/wutzup-swift
yarn check:wutzup:security
```

The API suite covers real Auth registration/disabled/deleted accounts, private
Hasura GraphQL, SQL persistence, concurrent retries/lost acknowledgements,
receipts/cursors, outsider/spoof denial, S3 uploads/capabilities/validation,
durable AI/tutor/GIF results and signed APNs HTTP/2 outbox delivery, retries and
invalid-token cleanup. A paused Hasura container must fail readiness and recover.
Only external AI/Apple provider boundaries are fixtures; they spend no money or
send real notifications. The SDK, SQL, storage and HTTP adapter code are real.

The UI suite uses the existing `wutzup.xcodeproj` through a generated test runner,
not a second app implementation. It exercises registration, new-chat selection,
sending, an independent peer session, polling, relaunch, read receipts, interrupted
sends, logout/login, account-owned drafts and queue replay. UI tests use synthetic
accounts and actual Firebase Auth SDK calls to the Auth emulator.

The runner patches **only the built Debug app copy** with a synthetic Firebase
demo-project configuration and signs that simulator artifact ad hoc for keychain
support. The source plist is hashed before/after and must remain unchanged. It
creates its own named simulator, trusts the temporary CA only there, and deletes
that simulator on completion. No production transport allowlist is weakened.
Release transport tests explicitly reject every emulator origin.

For a host without Docker, explicitly choose:

```sh
bash scripts/test-archlife-e2e.sh --embedded
```

This is the macOS hosted-CI mode: real Auth/HTTPS/Swift UI and SQL functions run
with PGlite and an in-memory object boundary. It does not prove Hasura or S3; the
Linux Docker gate is independently required. There is no automatic fallback or
silent skip. An occupied local HTTPS port 18443 must fail rather than stop its
existing listener. Run API and native suites sequentially on one host.

## Evidence and repeatability

Backend-owned ignored artifacts are under `.state/wutzup-e2e/`:

- `api/results.xml`, `api/runner.json`: complete API results and source identity.
- `native/build.log`, `native/test.log`, `native/result.json`, `native/api.json`,
  `native/runner.json`, timestamped `.xcresult`: build, UI/SQL evidence, redacted
  API traffic, exact source revisions, dirty-worktree flags and infrastructure mode.
- `security/summary.json`, `security/audit.jsonl`: dependency scan and blockers.

A successful native run requires every discovered release test to pass, with
zero skipped or missing tests. A zero-test Xcode result cannot pass. Failures keep
screenshots and accessibility hierarchies of synthetic test data. Keep real
credentials, user exports and capabilities out of artifacts. Do not upload the
private temporary context, TLS key or derived app contents.

Resources have a unique `org.archlife.wutzup.e2e` owner label and no host data
volumes. Cleanup targets only IDs allocated by that invocation. Container images
and Firebase CLI are pinned. Swift package downloads can reuse
`WUTZUP_E2E_SPM_CACHE`; `WUTZUP_E2E_DERIVED_DATA` changes the dedicated build cache.
Do not point either cache at valuable user-created outputs. Hard termination can
interrupt normal cleanup; inspect the exact owned IDs before any manual cleanup.
Never use broad Docker prune or erase unrelated simulators.

`bash scripts/test-offline-queue.sh` checks owner isolation, exact retry IDs,
synchronous acknowledgement persistence, suspended sends, bounded failures,
relaunch and legacy-data retention. `python3 scripts/test-offline-queue-mutations.py`
kills five meaningful privacy/retry mutants using temporary source copies.
The old unowned `offlineMessageQueue` and `wutzup_message_drafts` preferences are
retained for explicit recovery, never assigned to the next signed-in account.

## CI and release boundaries

The standalone native `.github/workflows/archlife-backend.yml` is now manual
(`workflow_dispatch`). Run its guard, transport, queue/mutation and Debug/Release
build commands locally for routine changes. The cloud's joint native/API release
jobs remain mandatory before its existing push-triggered deployment webhook.
See the runtime's [workspace local-check policy](../../../archlife-apps-runtime/docs/LOCAL_CHECKS.md).

Cloud `.github/workflows/archlife-runtime-deploy.yml` requires both
`wutzup-api-e2e` (Linux, actual infrastructure and critical dependency gate) and
`wutzup-swift-e2e` (macOS, explicit embedded mode and matching native Release build)
before its existing deployment webhook can run. Existing quality gates remain
required. The public native workflow also requires Debug/Release builds, transport
contracts, boundary checks, queue tests and mutations.

Publish the matching native candidate before running the private joint gate;
manual workflow dispatch accepts `wutzup_native_ref` for an exact revision.
Record that revision together with the backend SHA. Local dirty-source results
are development evidence, not proof that those revisions exist in CI. These
changes do not authorize a push or deployment.

The two critical dependency packages were patched during this verification:
Handlebars 4.7.10 and the transitive proxy-addr 2.0.8 resolution. The remaining
noncritical findings are recorded in the dated report.

The critical dependency gate fails closed for missing/malformed audit results.
Noncritical findings remain recorded for triage; passing this minimum gate does
not mean the whole dependency tree is vulnerability-free.

Before production release, separately prove current real Firebase sign-in,
production secrets/migrations/Hasura metadata and imported data, real private
object storage, physical-device APNs, signed archive/entitlements, App Store
validation, minimum-supported-iOS/device/accessibility coverage, appropriate
capacity, and a disposable backup restore. Provider fixtures do not establish
live AI quality, provider availability or Apple delivery. See the runtime's dated
release evidence and existing cutover/recovery procedure.
