# Wutzup 2.0.0 (2) release preparation

Observed 4 November 2026. This is preparation evidence, not a published release.

Release target updated on 5 November 2026 to **2.0.0, build 2** across Debug,
Release and the Wutzup website package. The checks and archive below were made
for the earlier 1.0.7 candidate; preserve that evidence as historical. A new
2.0.0 archive must be built and checked before upload. The build number remains
2 because no candidate was uploaded.

The candidate preserves `org.archlife.wutzup`, Apple team `5JRT57XQ6N`, native
SwiftUI, and the existing `wutzup-swift` Firebase Auth identity. Debug retains
`https://api-dev.archlife/api/wutzup`; Release embeds
`https://api.archlife.org/api/wutzup` in `WutzupAPIBaseURL`. Debug process overrides
and transport origin/redirect restrictions remain intact.

## Executed checks

- Firebase Auth-only dependency boundary and Debug/Release transport contracts passed.
- Offline queue/draft isolation regressions and all five native queue mutants passed.
- Backend build, Wutzup types, formatting, and cross-repository parity passed.
- The namespace audit passed schema/migration/contract, local DEV/PROD credential
  and URL wiring, and shared security integration checks.
- Backend behavior tests: 29 passed; dependency-gate behavior tests: two passed.
- SQL integration: ten passed; acceptance: six scenarios / 45 steps passed.
- Backend mutation checks: all 13 killed after adding the imported security
  modules to the disposable source copies. The initial incomplete-copy failure
  was not counted as a killed mutant.
- Firebase Auth emulator checks passed. The dependency scan reported zero
  critical/high, 21 moderate and one low finding.
- All nine API release E2E scenarios passed against disposable Docker PostgreSQL,
  Hasura, private S3 and Firebase Auth emulation. AI and Apple remain fixtures.
- Release simulator compilation and unsigned iPhone archive compilation passed.
  The candidate archive's actual bundle plist was checked for version `1.0.7`,
  build `2`, bundle ID, production API URL, iPhoneOS SDK 27.0 and minimum iOS 18.6.
  The bundled Firebase configuration matches the source plist's values exactly.
  The unsigned device executable SHA-256 is
  `5917e6e0fff1d293ca43ea9a8e4fe5d748f57335d4763765bc6f71621c1aa553`.

The initial native UI attempt timed out booting a disposable iOS 26.5 simulator.
An explicit installed-runtime selector was added to the backend runner; it
continues to allocate its own simulator and fails for unavailable identifiers.
On iOS 26.0, registration exposed a test-driver Password AutoFill focus issue:
the field contained one character and the app correctly rejected the short
password. Queue/account isolation and messaging/relaunch scenarios passed.
The driver now pastes the known synthetic password through the real edit menu,
restores the disposable simulator clipboard, and lets registration/login verify
the submitted input. The final complete iOS 26.0/Docker run passed all three UI
scenarios with zero failures or skips: registration/new conversation/persistence,
account-owned queues/drafts, and signed-in messaging/relaunch/peer updates. The
runner verified that the Firebase source plist and native source fingerprint
remained unchanged. Its result bundle is `release-1793841969472.xcresult`.

## Live cutover findings

Both public Wutzup API health routes return 200 and anonymous readiness returns
401. Both hosted environments have Wutzup tables/functions, the correct Firebase
project, and nonempty AI, Hasura and S3 configuration. These observations do not
prove real authenticated persistence, object delivery or provider behavior.

Read-only hosted DEV and PROD queries found zero users, conversations, messages,
media and import runs. Releasing new clients before import would expose empty
accounts. No hosted data was changed.

A fresh read-only export with an existing authorized Google account exactly
matched the reviewed export for all 35 users, 74 conversations, 3,086 messages and
37 presence records. The existing production-origin import plan therefore
retains its stable media capabilities. Isolated snapshot verification preserved
every message's ID/content/timestamp/receipts, with three recovered media objects,
four missing-media recovery records and two archived orphan presence records.
This verification did not modify a live database.

A separate DEV-origin import plan was also prepared and passed the same isolated
snapshot proof. It uses DEV URLs; the original production plan was preserved.

Both hosted environments lack `WUTZUP_APNS_KEY_ID` and
`WUTZUP_APNS_PRIVATE_KEY`. A configured Team ID alone does not provide push.
An existing valid key must be recovered or a new key separately authorized;
configuration, provider validation and physical-device delivery remain pending.

## Apple release status and remaining work

Proposed What's New: "Messaging reliability improvements, more consistent
conversation syncing, and fixes for offline message delivery."

App Store Connect shows version 1.0.6 ready for distribution; its latest
TestFlight build is expired. No 1.0.7 build was present. Xcode's existing account
was successfully reauthenticated. Signed archiving failed with Apple's
`PLA Update available` response. Attempting to create the App Store version
also produced an Agreement Update dialog. The Account Holder must personally
review and accept the updated Apple Developer Program License Agreement.

After the pending decisions and checks:

1. Obtain explicit cutover/deferred-media authorization, preserve the current
   legacy rules and rollback artifacts, freeze legacy writes, and refresh the
   final snapshot again before import. Apply and verify DEV before PROD.
2. Resolve APNs credentials and reconcile the intended environment configuration.
3. Verify real Firebase login, independent-session SQL persistence/authorization,
   media/provider behavior, signed-device APNs and disposable backup restoration.
4. After the Apple agreement is accepted, create a signed Release archive,
   inspect its actual provisioning and APNs entitlement, validate/upload it,
   select the processed build in version 2.0.0, and submit for Apple review.
   Store metadata, privacy disclosures, age rating and reviewer access must
   match the final app. Apple approval and distribution are separate states.

No Git commit/push, runtime deployment, live import, Firebase rule change,
credential creation/publication, App Store upload or review submission occurred.

Ignored native artifacts are in `.state/app-store-release/`, including
`Wutzup-1.0.7-2-candidate.xcarchive` (unsigned), build logs and the failed signed
archive log. Backend evidence is in
`services/typescript-cloud/.state/wutzup-app-store-20261104/` and
`.state/wutzup-e2e/`. Exports and capabilities remain private and untracked.

## Signed 2.0.0 attempt, 5 November 2026

A fresh Release device archive of source
`680200ed5bd380ea2c8c2809f363d59592daa978` was attempted with the existing
`org.archlife.wutzup` identity, version `2.0.0`, build `2`, team `5JRT57XQ6N`,
and `-allowProvisioningUpdates`. Xcode exited 65 with `No Accounts` and no
provisioning profile for this bundle. The log is retained at
`.state/app-store-release/v2-signed-20261105/archive.log`. No signed archive or
IPA was produced or uploaded. The earlier Apple agreement finding above was
not reverified because Computer Use was unavailable.

The request includes Android. This checkout contains the SwiftUI iOS client;
no Android client was found in the workspace or the connected GitHub account.
An existing Android repository must be supplied, or an Android client must be
implemented before an Android release is possible. The available Google Play
credential catalog covers Translate Wallpaper, not Wutzup.

The [four-target release status](../../class-escolar/@docs/MOBILE_RELEASE_2026-11-05.md)
records the current blockers and resume requirements. No tests, live import,
backend deployment, credential creation, Git publication, or store submission
occurred in this attempt.

## Signed App Store candidate, 5 November 2026 follow-up

Wutzup **2.0.0 (2)** now has a signed App Store archive and exported IPA.
Apple's live build history showed no existing `2.0.0 (2)` upload. The exact
candidate uses source commit `680200ed5bd380ea2c8c2809f363d59592daa978` plus
the APNs entitlement correction in the working tree; the source fingerprint is
recorded in the artifact receipt. Debug now resolves `aps-environment` to
`development`, Release to `production`, and the unsupported duplicate
`com.apple.developer.aps-environment` key was removed.

The Release device archive was compiled locally with Xcode 27.0 / iOS 27.0 SDK.
Its archive transfer SHA-256 was checked on the Mac mini. Signing and Xcode
App Store export then ran on the Mini using the existing dedicated Keychain,
without exporting its private distribution key. The first headless signature
attempt failed with `errSecInternalComponent`; unlocking the Keychain and
authorizing its existing signing key in the same SSH session resolved it.

- Apple team: `5JRT57XQ6N` (Landscape Supply Inc.).
- App Store app: `6754276286`; bundle: `org.archlife.wutzup`.
- Distribution certificate: `32F8U2463F`.
- App Store provisioning profile: `CDNG6N3793`, UUID
  `16b8d40d-0a92-4d7e-8e30-07bcaff84f8e`.
- Local IPA: `.state/app-store-release/signed-20261105/Wutzup-2.0.0-2.ipa`.
- IPA SHA-256: `c81652a9ea878ac50a354592c183967e9e84ccd445d325e623f68c5a0a45335b`.
- Local evidence: `.state/app-store-release/signed-20261105/build-receipt.json`.
- Signed archive on the Mini:
  `~/.local/share/wutzup-release/runs/2.0.0-2-20261105/Wutzup-2.0.0-2.xcarchive`.
  The local archive of that name is the unsigned compilation input.

Validation passed: Firebase Auth-only boundary, Debug/Release native transport
and executed-PostgreSQL response contracts, plist syntax, Release archive,
signed archive verification, Xcode App Store IPA export, matching transferred
IPA checksum, and local `codesign --verify --deep --strict` on the exported app.
The final packaged app/profile agree on team, bundle, version/build and
production APNs; `get-task-allow` is false and the profile has no device list.
The actual packaged Release API is `https://api.archlife.org/api/wutzup`.

No upload, TestFlight processing, review submission or publication occurred.
This signing result does not verify or complete the historical-data cutover,
live authenticated journeys, server APNs configuration, physical-device push,
or backup restoration described above. Those remain distribution-readiness
checks. Class Escolar signing remains blocked by its separate new-organization
prerequisites; see the paired release status.

The owner later clarified that Wutzup and Class Escolar are separate apps owned
by the same organization. The earlier separate-team restriction is superseded.
Class Escolar `org.archlife.classescolar` **2.0.0 (3)** has now been signed under
the same team `5JRT57XQ6N`, using its own profile and Keychain access group. The
Wutzup IPA above remains unchanged and its checksum was reverified. See the
paired release record for both candidates and the Class Escolar store-record
step that remains before upload. Neither candidate was uploaded.
