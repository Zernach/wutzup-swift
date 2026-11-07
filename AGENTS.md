# Wutzup agent guide

This repository is the **native SwiftUI Wutzup application**. Its application
backend belongs to the existing Archlife TypeScript API and private PostgreSQL
namespace. Firebase remains the existing identity provider. Preserve this
architecture when changing the app.

Last source audit: **23 October 2026**. Dates, deployment status, installed tools,
credentials and historical test counts are observations, not permanent facts.
Recheck the relevant source and environment before relying on them.

## Essential context

- Native checkout: `/Users/zernach/code/archlife-apps-frontends/wutzup-swift`.
- Source directory: **`Wutzup/`**, with uppercase `W`. Project, scheme and product:
  **`wutzup.xcodeproj`**, **`wutzup`**, **`wutzup`**. Preserve that capitalization.
- Archlife namespace/project selector: `wutzup` / `PROJECTS.WUTZUP`.
- PostgreSQL database/role: `wutzupdb` / `wutzupuser`, isolated per environment.
- API prefix: `/api/wutzup`.
- Existing Firebase project and token audience: `wutzup-swift`.
- iOS bundle ID: `org.archlife.wutzup`. Xcode Apple Team ID: `5JRT57XQ6N`.
- Keep existing Firebase UIDs, conversation IDs, message IDs and tutor metadata.
- Application persistence, AI, media and push use Archlife. The old Firebase
  database/functions code is migration/reference material.
- `src/shared/wutzup/` contains generated TypeScript contract references. It is
  not a JavaScript frontend or the implementation of the Swift models.
- The migration's local implementation and isolated verification do **not** prove
  a live cutover. See the dated status and release checklist below.

## Read first and choose the owning repository

Read [the migration contract](docs/backend-migration.md),
[native verification notes](docs/backend-verification.md),
[the integrated release workflow](docs/release-testing.md),
[the app manifest](archlife-app.json), and the files that implement the requested
behavior. The runtime's [AGENTS.md](../../archlife-apps-runtime/AGENTS.md) applies
when working in that repository. Read any additional instructions in each owning
checkout before editing it.

| Checkout | Responsibility | Main entry points, relative to that checkout |
| --- | --- | --- |
| This repository | SwiftUI, MVVM, local caching, Firebase Auth client, authenticated API transport, device registration | `Wutzup/App/`, `Wutzup/Services/`, `Wutzup/Models/`, `Wutzup/ViewModels/`, `Wutzup/Views/` |
| `/Users/zernach/code/archlife-apps-runtime` | Host/runtime configuration, per-environment secrets, database provisioning, networking, deployment and backups | `AGENTS.md`, `bin/archlife`, `scripts/runtime/runtime-tools/src/bin/`, `scripts/secrets/onboard-wutzup.py` |
| `/Users/zernach/code/archlife-apps-runtime/services/typescript-cloud` | Wutzup HTTP API, authorization, business/AI logic, S3 media, APNs worker, import operator tools | `routes/wutzup/index.ts`, `controllers/wutzup/`, `scripts/migrations/` |
| `/Users/zernach/code/archlife-apps-runtime/services/python-cloud` | Authoritative SQLAlchemy schema, SQL functions, migrations, Hasura registration, admin and backup inventory | `actions/create/wutzup/`, `actions/migrations/wutzup/`, `config/config.py`, `utils/namespace_resources.py` |
| `/Users/zernach/code/archlife-apps-runtime/services/shared-types` | Canonical TypeScript DTOs, validation, operation/action lists and project enum | `src/types/wutzup/`, `src/types/shared-types.ts`, `src/types/index.ts`, `copy.sh --wutzup` |

These are separate Git checkouts. A change in this app does not publish backend
changes. Inspect each relevant worktree and preserve existing staged, unstaged
and untracked work. Use `rg` for targeted discovery.

The runtime's [verification report](../../archlife-apps-runtime/docs/wutzup-backend-verification.md)
and [acceptance criteria](../../archlife-apps-runtime/docs/wutzup-data-acceptance.md)
contain the detailed historical evidence. Older `@docs/`, `XCODE_SETUP.md`,
`iOS_PROJECT_SUMMARY.md`, Firebase deployment guides and package notes contain
pre-migration assumptions. Confirm them against current source; do not restore
Firestore/FCM/Python application traffic merely to match an old document.

## Scope, authorization and preservation

1. Complete the requested code, documentation and proportionate verification
   within the user's authorized scope. Existing authorization persists.
2. Git mutations/publication, deployment, live schema/data changes, remote secret
   publication, billing/IAM changes and retiring Firebase resources require
   explicit authorization. Read-only status/diff inspection is appropriate.
3. Runtime commands can affect every application on the shared host. Inspect
   their implementations and current help before invoking operational commands.
4. Keep private exports, real messages, tokens, API keys, signing keys, database
   passwords and media capabilities out of source control, logs and screenshots.
   Check configuration through presence/equality assertions rather than printing
   complete env files. Do not shell-source untrusted env files.
5. Preserve simulator/application data, existing SwiftData stores, original
   exports, caches useful for recovery and unrelated work. Do not erase them to
   make a build or migration appear successful.
6. Database changes require an ordered migration in Python cloud. Do not edit an
   already-applied migration or patch a live database as the only implementation.
7. Use the relevant runtime `sync-db-code`/`create-archlife-app` skill for ecosystem
   changes, while respecting this existing app's Swift/Firebase Auth design and
   the user's deployment boundary. This task does not call for a replacement
   React Native Web frontend, a new Firebase project or new Google OAuth identity.

## End-to-end request flow

```text
SwiftUI views / view models
  -> service protocols and Archlife*Service implementations
  -> ArchlifeWutzupAPI: current Firebase user's ID token
  -> HTTPS /api/wutzup on the existing TypeScript service
  -> Firebase token/account-state verification; server-owned actor UID
  -> strict action/operation validation and business authorization
  -> private Hasura function in the wutzupdb source
  -> environment-specific PostgreSQL wutzupdb

Media: authenticated upload / generated GIF -> private Archlife S3 object
       -> SQL metadata + object-scoped capability URL -> native ImageCache

Push: SQL message transaction -> durable SQL outbox -> TypeScript APNs worker
      -> Apple -> native notification delegate -> conversation navigation
```

The app never receives Hasura administrator credentials, PostgreSQL passwords,
OpenAI keys, S3 credentials or the APNs signing key. The Firebase client key in
the plist is not the OpenAI key and is not an APNs provider signing credential.

## Native architecture and lifecycle

| Area | Files to inspect |
| --- | --- |
| Launch, SwiftData schema and notification callbacks | [WutzupApp.swift](Wutzup/App/WutzupApp.swift) |
| Service construction, authentication observation, reconnect/foreground handling, pending APNs token | [AppState.swift](Wutzup/App/AppState.swift) |
| Dependency interfaces and previews | `Wutzup/Services/Protocols/` |
| Identity operations and API profile bootstrap | [FirebaseAuthService.swift](Wutzup/Services/Firebase/FirebaseAuthService.swift) |
| Authenticated HTTP transport | [ArchlifeWutzupAPI.swift](Wutzup/Services/ArchlifeWutzupAPI.swift), [WutzupRequestTransport.swift](Wutzup/Services/WutzupRequestTransport.swift) |
| Request construction, wire dates, response/error decoding | [WutzupWire.swift](Wutzup/Services/WutzupWire.swift) |
| Application API adapters | `Wutzup/Services/Archlife/` |
| Polling, cancellation and backoff | [WutzupPolling.swift](Wutzup/Services/Archlife/WutzupPolling.swift) |
| Domain versus persistent local models | `Wutzup/Models/Domain/`, `Wutzup/Models/SwiftData/` |
| Offline retry queue and network state | [OfflineMessageQueue.swift](Wutzup/Services/Local/OfflineMessageQueue.swift), `Wutzup/Utilities/NetworkMonitor.swift` |
| Background/foreground coordination | `Wutzup/Utilities/AppLifecycleManager.swift` |
| Images, GIFs and safe response caching | `Wutzup/Utilities/ImageCache.swift`, [WutzupMediaResponse.swift](Wutzup/Services/WutzupMediaResponse.swift) |
| Research citation display | `Wutzup/Services/WutzupResearchText.swift`, `Wutzup/Views/Components/ResearchView.swift` |

The application constructs `MessageModel`, `ConversationModel` and `UserModel`
in one persistent SwiftData container. Evolve that schema deliberately; model
changes must account for an existing installation's data. Some unused legacy
fields, such as the local user model's `fcmToken`, remain for compatibility and
do not establish an active Firebase Messaging integration.

`AppState` owns the shared services and chat-list model. Views/view models consume
the service interfaces. Keep networking and backend rules out of SwiftUI view
code. Several domain/wire types use `nonisolated` annotations to work with current
Swift actor isolation; do not remove them just to silence a compiler error.
The root currently forces dark mode; shared appearance tokens live in
`Wutzup/Utilities/Constants.swift`. Preserve the existing visual design unless
the requested change includes a redesign.

Authentication listeners cancel stale profile work and check the current UID
before publishing results. The app can retain a Firebase identity while the API
is temporarily unavailable; a signed-in screen is not proof that SQL profile
bootstrap or persistence succeeded.

Polling uses a bounded `AsyncStream`, a normal two-second interval, transient-error
backoff up to 30 seconds, termination on 401/403 and cancellation when the account
or consuming task changes. Presence heartbeats run every 45 seconds; SQL expires
online presence after 90 seconds and typing after 10 seconds. Preserve cancellation
on logout, view termination and background/lifecycle transitions.

## Environments, project settings and local development

| Setting | Current contract |
| --- | --- |
| Debug API default | `https://api-dev.archlife/api/wutzup` |
| Public development API | `https://api-dev.archlife.org/api/wutzup` |
| Release API default | `https://api.archlife.org/api/wutzup` |
| Debug process override | `WUTZUP_API_BASE_URL` |
| Bundle override key | `WutzupAPIBaseURL` |
| Local edge alternative allowed by the transport | `https://api-dev.archlife:18443/api/wutzup` |
| Current iOS deployment target | 18.6; recheck `project.pbxproj` when changing compatibility |
| Current stored Swift language setting | `SWIFT_VERSION = 5.0`; this does not mean an old Swift compiler supports the current source |
| Toolchain observed on 22 October | Xcode 27.0, Apple Swift 6.4 |

`WUTZUP_API_BASE_URL` is read from the process environment in Debug only. Release
uses the bundle override or its public production default. All overrides still
pass transport validation: HTTPS, an explicitly allowed host/port, `/api/wutzup/`
path, and no credentials/query/fragment. Redirects are rejected before they can
forward a Firebase bearer token to another location. Keep these protections.

`.archlife` names are local aliases; `.archlife.org` names are public/remote.
For local DNS/TLS problems, inspect the runtime's `doctor-local-edge` and
`print-hosts` facilities. Editing hosts or trusting certificates changes the
machine; do so only within scope. Do not silently switch to a remote data
environment to bypass a local certificate problem.

Open the existing project with `open wutzup.xcodeproj`. Files under `Wutzup/`
are managed by a filesystem-synchronized Xcode group; inspect membership
exceptions before adding hand-maintained build entries. Use `build.sh`, whose
default derived-data directory is `build-archlife/`, or an explicit isolated
`WUTZUP_DERIVED_DATA_PATH`. The historical `build/` cache contains moved-checkout
paths and is not the preferred cache. An unsigned simulator build installs
nothing on a physical device and does not deploy the backend.

## Authentication and account workflow

1. `FirebaseAuthService` registers/signs in/resets passwords through the existing
   Firebase Auth project configured by `Wutzup/Resources/GoogleService-Info.plist`.
2. Registration/login and auth restoration call API `bootstrap` for the same UID.
   Profile edits go through API `profile`; the database is authoritative for
   application profile/tutor/language metadata.
3. `ArchlifeWutzupAPI` obtains the current Firebase ID token and attaches it through
   the restricted transport. API actor identity comes from the verified token,
   never a client-supplied actor, email, sender, role or tutor flag.
4. TypeScript `controllers/wutzup/firebase.ts` uses a named Firebase Admin app,
   project-bound public signing certificates and user-scoped Auth `accounts:lookup`
   with the existing Firebase client key. It checks disabled/deleted/revoked
   account state and rejects anonymous identities. This flow does not need a new
   service-account private key. Do not borrow another app's `FB_*` credentials.
5. Logout attempts device unregistration before Firebase sign-out; subscriptions
   must stop and account-scoped UI/caches must not leak to the next identity.
6. Account deletion requires recent authentication (five-minute API threshold),
   tombstones the SQL profile/removes registrations, then deletes the Firebase
   identity. Preserve message evidence and handle partial failure explicitly.

The default `firebase/firebase.json` configures **Auth emulation only**, port
9099 (UI 4000). The service test runner owns its isolated `demo-wutzup` project.
Native Debug can use `FIREBASE_AUTH_EMULATOR_HOST`; ensure the client project,
API expected audience and emulator configuration actually agree. Production
API configuration rejects an Auth emulator. Do not use real user data to seed
emulator fixtures.

## Messaging, synchronization and authorization invariants

- `ArchlifeChatService` paginates conversations and reuses direct conversations
  by participant identity. A new UUID is not permission to create duplicate
  direct threads. Group invitations use `add_members` to merge participants
  atomically; other edits use server revisions and conflict handling.
- A send starts with a stable message ID. `ArchlifeMessageService.sendMessage`
  uses it in the body and as the request key. Offline retries must keep that ID,
  content and intent; retrying the same send must not create a second message.
- SwiftData caches display state; `OfflineMessageQueue` persists pending sends
  in UserDefaults and retries on reconnect/foreground, stopping automatic retry
  after five failures. Distinguish failed local state from a committed server
  message whose acknowledgement was lost.
- SQL message identity is `(conversation_id, id)`. Timestamps, sender identity,
  receipt ownership and tutor role are server-controlled for new writes.
- Message sync uses `(updated_at, id)` cursors so receipt changes and equal-time
  messages remain observable. Do not reduce the cursor to a timestamp alone or
  replace bounded synchronization with an unbounded history fetch.
- The API validates current membership on reads, writes and replay. Removing a
  participant must also prevent replaying a cached AI response or writing a tutor
  reply after generation finishes. Never treat a client participant list as proof.
- Other users' private profile fields must stay out of directory responses.
  Clients cannot self-promote to tutor. Existing tutors can have ordinary Firebase
  UIDs; a synthetic `tutor_` prefix is not the role check.
- AI request receipts persist fingerprints, leases, quotas and results in SQL.
  Same intent returns the original result; changed intent conflicts; active
  leases fence concurrent workers and expired leases fence stale completion.
- A completed receipt must survive a lost HTTP acknowledgement. A persisted GIF
  or tutor message must recover on retry without another provider call, including
  when a daily quota has subsequently been exhausted.

**Account-owned local state:** AppState activates queue v2 with the authenticated
UID, hides it on logout and retries only that owner's messages. Late responses
cannot drain the next account's queue. DraftManager instances bind to the account
that opened their view. The old unowned `offlineMessageQueue` and
`wutzup_message_drafts` values are retained for explicit recovery and never
assigned to a newly signed-in account. Run focused queue/draft regressions,
mutations and the native account-switch scenario after changing this lifecycle.
Shared cache/listener behavior still needs authorization and cancellation checks;
server membership alone cannot establish native privacy.

## TypeScript API and AI workflows

The Wutzup router is mounted early in `typescript-cloud/app.ts`, before the broad
middleware. Relevant server modules are `routes/wutzup/index.ts` and
`controllers/wutzup/{firebase,store,service,provider,prompts,media,notifications,migration}.ts`.
The legacy default Firebase helper explicitly selects `[DEFAULT]`; preserve its
isolation from Wutzup's named app and its regression test.

| Endpoint | Purpose and access |
| --- | --- |
| `GET /api/wutzup/health` or `/health_check` | Anonymous liveness; not database/identity proof |
| `GET /api/wutzup/ready` | Authenticated saved-profile/SQL and AI-configuration check; also reports `media_configured` and `push_configured` |
| `POST /api/wutzup/data/:action` | Authenticated, strict public data-action allowlist |
| `POST /api/wutzup/:operation` | Authenticated, validated AI operation with durable request key |
| `POST /api/wutzup/media` | Authenticated JPEG/PNG bytes, five-MiB HTTP limit, durable request key |
| `GET /api/wutzup/media/:id/:capability` | Object-scoped capability access; the URL is sensitive access material |

The public data actions cover bootstrap/directory/profile/account deletion;
conversation list/create/read/update/invite; send/history/sync/receipts; presence
and typing; device register/unregister. The exact list and fields live in
canonical `src/types/wutzup/data.ts`. Internal AI receipt, tutor-publish,
media-register, outbox and import actions must not become public data actions.

The eight AI operations are `generate_response_suggestions`, `translate_text`,
`message_context`, `language_tutor`, `conduct_research`, `generate_gif`,
`generate_tutor_greeting` and `generate_tutor_response`. Their operation names,
snake-case AI response fields and native wrappers are compatibility contracts;
data DTOs mostly use camelCase. Test Swift decoding whenever changing them.

Requests require `Idempotency-Key` (8–128 allowed characters) on POST data/AI/media
routes. JSON bodies are bounded to 64 KiB; public data pages/receipt batches are
bounded to 200 and conversation membership to 100. Use canonical validators
instead of duplicating or weakening these rules. SQL enforces persisted daily
budgets; inspect its current categories/limits when changing quota behavior.

`PROJECTS.WUTZUP` selects only `OPENAI_4_API_KEY_WUTZUP` through
`constants/models.ts`. Keep the existing app's key and fail closed if missing.
Provider/model changes must retain bounded inputs/outputs, timeouts, redacted
errors and versioned evaluations in `controllers/wutzup/evals.v1.json`.
Text translations, research citations and GIF generation have distinct contracts.
Research requires actual completed hosted search/citations. GIF generation
encodes two image frames into an animation; it is not a renamed still image.
Tutor generation loads saved membership, tutor identity/personality and relevant
conversation history on the server and publishes a deterministic message ID.

## Media and direct APNs

`ArchlifeWutzupMedia` uses the runtime's existing S3-compatible configuration:
`SPACES_ENDPOINT_URL`, `SPACES_ACCESS_KEY`, `SPACES_SECRET_KEY`,
`SPACES_BUCKET_FILES`. The names are historical; inspect the selected endpoint
instead of assuming they mean a separate DigitalOcean account. Objects are
private. SQL stores media metadata/capability hashes; API URLs grant access only
to their object. Do not publish bucket credentials or put bearer tokens in URLs.

Profile uploads are normalized/bounded images. The native media-response helper
checks HTTP status, content type, signatures and size before caching, rejects
legacy Firebase/GCS network downloads, and allows already-valid cached bytes.
Keep error bodies out of the image cache so a temporary 403/503 can recover.

`ArchlifeNotificationService` registers the raw APNs device token with the API,
not an FCM token. `AppState` coordinates registration with identity and pending
token state. SQL messages enqueue eligible recipients; the server's five-second
worker processes bounded batches through Apple HTTP/2/ES256, retries failures,
excludes the sender/tutors as appropriate and clears invalid tokens conditionally.
The worker does not claim jobs when push is unconfigured.

Debug registers sandbox and non-Debug registers production. The checked-in
`aps-environment` entitlement resolves through `WUTZUP_APNS_ENVIRONMENT` to
`development` in Debug and `production` in Release. Verify the actual signed entitlement,
provisioning profile, bundle ID, token environment and target Apple endpoint for
device/TestFlight releases. Build success cannot establish APNs delivery.

## Credential provenance and safe onboarding

| Variable | Source / meaning |
| --- | --- |
| `OPENAI_4_API_KEY_WUTZUP` | Existing `OPENAI_API_KEY` from ignored native `firebase/functions/.env`; belongs to the TypeScript service |
| `WUTZUP_FIREBASE_PROJECT_ID` | Existing `wutzup-swift` identity project |
| `WUTZUP_FIREBASE_WEB_API_KEY` | Existing `API_KEY` in `Wutzup/Resources/GoogleService-Info.plist`; Auth account lookup, not AI authorization |
| `WUTZUP_MEDIA_ORIGIN` | Renderer-owned selected API origin; normally blank in the input template |
| `WUTZUP_APNS_TEAM_ID` | Recovered unambiguously from Xcode `DEVELOPMENT_TEAM`; currently `5JRT57XQ6N` |
| `WUTZUP_APNS_KEY_ID` | ID of the Apple APNs signing key; not a Firebase key or a device token |
| `WUTZUP_APNS_PRIVATE_KEY` | Corresponding original `.p8` signing key; server supports escaped `\n` newlines |
| `POSTGRES_DEV_WUTZUP_PASSWORD`, `POSTGRES_PROD_WUTZUP_PASSWORD` | Runtime core secrets; preserve valid existing values |
| `HASURA_ENDPOINT`, `HASURA_ADMIN_SECRET` | Private server invocation configuration; never mobile settings |

The original Python push path called Firebase Messaging. On 22 October the
original checkout contained neither an APNs key ID setting nor a `.p8` file.
The Firebase client key and Apple Team ID were recovered and synchronized;
the APNs key ID/private key remained unresolved. Do not fabricate them, substitute
an unrelated signing key, or claim push works because the Team ID is present.
Firebase/Apple configuration or an existing private credential backup may hold
the needed material. Creating/revoking a key is a separate authorized operation.

Runtime secret locations have different roles:

- `env/apps.dev.env`, `env/apps.prod.env`: ignored materialized app configuration.
- `secrets/apps.dev.env`, `secrets/apps.prod.env`: app values consumed by runtime
  rendering; editing a template or only a local materialized file is insufficient
  to establish the generated service configuration.
- `services/typescript-cloud/.env.dev`, `.env.prod`: service-local configuration.
- `secrets/vaultwarden/{dev,prod}/source-of-truth.env`: scoped local catalogs;
  service keys use `ARCHLIFE_TYPESCRIPT_CLOUD_DEV__` and
  `ARCHLIFE_TYPESCRIPT_CLOUD_PROD__` prefixes.
- `secrets/core.env`: internal runtime passwords, including Wutzup DEV/PROD.
- `env/pyweb.env`: materialized Python schema/admin URLs, not the Wutzup AI key.
- `.state/generated/`: renderer outputs, including cloud DEV/PROD and blue/green
  variants, `pyweb.env`, `init.env` and `postgres-local.env`; not authoritative
  files to hand-edit or commit.
- `env/*.example`: committed names/defaults, not evidence that real values are
  missing. Never fill these templates with private keys/passwords.

For an **authorized local onboarding/configuration repair**, from the runtime
root, use the repository-owned sequence below. If an existing database's
authoritative password is missing, recover it before generating a replacement.

```sh
cd /Users/zernach/code/archlife-apps-runtime
./bin/archlife secrets-init
./bin/archlife render
python3 scripts/secrets/onboard-wutzup.py \
  --runtime /Users/zernach/code/archlife-apps-runtime \
  --source /Users/zernach/code/archlife-apps-frontends/wutzup-swift/firebase/functions/.env
python3 .agents/skills/create-archlife-app/scripts/check_namespace.py \
  --runtime /Users/zernach/code/archlife-apps-runtime \
  --frontend /Users/zernach/code/archlife-apps-frontends/wutzup-swift \
  --namespace wutzup
./bin/archlife render
./bin/archlife doctor
```

The first render supplies validated environment-specific DB URLs to onboarding.
The helper preflights destinations, refuses conflicts/tracked secret targets and
symlinks, preserves unrelated entries, imports existing OpenAI/Firebase/Team ID
values, updates the four Python DB URLs, and is byte-idempotent. It does not
discover an absent APNs private key or publish a remote vault. Explicit APNs key
configuration must also be kept consistent with the renderer's app-secret source
and the intended scoped catalog.

The four Python URL variables are `DEV_DATABASE_WUTZUP_URL`,
`PROD_DATABASE_WUTZUP_URL`, `LOCAL_DEV_DATABASE_WUTZUP_URL` and
`LOCAL_PROD_DATABASE_WUTZUP_URL`. Internal Docker hosts/ports and workstation or
managed-host routes differ. Reuse the renderer instead of constructing a second
URL builder or copying one URL into every environment.

`secrets-materialize` decrypts existing SOPS data; it does not create missing
namespace passwords. Local catalog changes are not remote Vaultwarden publication.
Use the runtime's existing scoped build/push/verify workflow only within the
authorized scope; do not overwrite unrelated catalogs or pull stale data over
newly generated authoritative credentials.

## Changing contracts, SQL and runtime wiring

1. Change canonical contracts in shared-types `src/types/wutzup/`; keep the
   project enum/root barrel consistent. Add behavior tests for the changed rule.
2. Fan out narrowly, from shared-types:

   ```sh
   cd /Users/zernach/code/archlife-apps-runtime/services/shared-types
   bash copy.sh --wutzup
   yarn build
   python3 -m unittest discover -s tests -p 'test_wutzup_copy.py'
   ```

   This refreshes cloud `@landscapesupply/types/wutzup/`, this repo's
   `src/shared/wutzup/`, and the required cloud enum/barrel. Refusal on unrelated
   drift is intentional. Do not hand-edit generated consumers or use unscoped
   `copy.sh` to repair one namespace: broad fan-out includes deletion behavior.
3. Update actual Swift domain/wire models and services separately. Copying the
   TypeScript files does not update Swift `Codable` behavior.
4. Authoritative schema/functions are Python cloud `actions/create/wutzup/`.
   Ordered migration metadata is under `actions/migrations/wutzup/`. The initial
   schema is `001_initial.json` with `_order.json`; inspect the actual order when
   adding a later migration. Preserve applied migration identities/history.
5. Keep Python `DATABASES`, `NamespaceResources`, table/model tracking, function
   tracking, administrative creation and `backup_subdir="wutzup"` aligned.
   Tables include users, conversations, messages, presence, request receipts,
   quotas, devices, push jobs, media, import receipts and legacy recovery records.
6. Keep private functions `wutzup_private`, `wutzup_system`, `wutzup_import` and
   their revoked public permissions aligned with the Hasura source `wutzupdb`.
   The TypeScript store is the server-only invocation boundary, not a public SQL
   proxy. Track registration does not itself prove live Hasura metadata converged.
7. Sync the current SQL test fixture and regenerate SQL-derived Swift wire
   responses from cloud, then run the native test:

   ```sh
   cd /Users/zernach/code/archlife-apps-runtime/services/typescript-cloud
   node scripts/sync-wutzup-schema.mjs
   yarn tsx scripts/sync-wutzup-native-fixture.ts
   yarn check:wutzup:parity
   yarn tsx scripts/sync-wutzup-native-fixture.ts --check
   cd /Users/zernach/code/archlife-apps-frontends/wutzup-swift
   bash scripts/test-archlife-backend.sh
   ```

   The schema synchronizer currently consumes `001_initial.json`; if adding later
   migrations, evolve the fixture/synchronizer to exercise the ordered chain.
   Do not hand-maintain a divergent second schema. Synthetic inputs live in cloud
   `tests/support/wutzup-legacy-fixture.json`; executed SQL responses fan out to
   cloud `tests/support/wutzup-native-contract.json` and native
   `tests/fixtures/archlife-api.json`.
8. Runtime namespace changes span Rust `render.rs`, `generate-secrets.rs`,
   `doctor.rs`, `runtime-config.rs`, private role/DB provisioning and generated
   URL maps. Add deterministic tests for routing, repeated rendering, password
   preservation and permission boundaries; run the namespace audit on actual
   nonempty materialized DEV/PROD passwords.

## Historical data import and recovery

Operator CLI: cloud `scripts/migrations/wutzup.ts` through `yarn migrate:wutzup`.
It is excluded from the production TypeScript build; Firestore access is confined
to the explicit legacy export path. Never reintroduce it into the live data store.

| Command | Effect |
| --- | --- |
| `export --project wutzup-swift --account ... --output /absolute/private.json` | Read original Firestore through an existing authorized identity; write private snapshot |
| `hydrate-media --input ... --account ... --output ...` | Read permitted legacy media into a separate snapshot artifact |
| `recover-cache --input ... --cache-dir /absolute/cache --output ...` | Recover validated existing local image bytes without fetching Firebase |
| `prepare --input ... --origin ... --output ...` | Offline normalization, media conversion, stable capability mapping and reviewed import plan |
| `check --input ...` | Offline artifact validation/counts |
| `apply --input ... --apply --environment dev\|prod` | Live S3/Hasura mutation; separate explicit authorization required |

Artifacts use absolute, non-symlink paths, mode 0600; inside a repository their
destinations must be ignored. Different content cannot overwrite an existing
artifact. Preserve the original snapshot and reviewed plan. Capabilities are
random access material; regeneration changes referenced URLs.

Private snapshot artifacts from the migration are in cloud `.state/wutzup/`:
`legacy-export.json`, `cache-recovered-export.json`, `review-import.json` and
`review-import-verification.json`. Check that they still exist before using them;
they are local private files, not files guaranteed in a fresh clone.

The reviewed October snapshot contained **35 profiles (20 tutors), 74 conversations,
3,086 messages and 37 presence records**. Three of seven media objects were
recovered from simulator caches; four were unavailable because the legacy Google
Storage billing account was closed. Missing media retains exact private recovery
references. Two orphan presence records are archived instead of inventing users.
Historical duplicate/self membership and former senders are preserved without
weakening current-membership authorization for new writes.

Preparation fails on unavailable media unless `--defer-media` is explicit. That
acceptance is also required when reusing/applying a deferred plan. Reuse/apply
must match the selected API media origin. Apply requires `ENVIRONMENT` to match
the explicit dev/prod target, uploads objects before one database import
transaction, rejects invalid references, and accepts exact replay without
overwriting later application edits. Invalid data must roll back atomically.

Repeat the **offline, isolated** full-snapshot proof from cloud when those
private artifacts are available:

```sh
yarn migrate:wutzup check --input "$PWD/.state/wutzup/review-import.json"
yarn verify:wutzup:snapshot \
  --source "$PWD/.state/wutzup/cache-recovered-export.json" \
  --prepared "$PWD/.state/wutzup/review-import.json"
```

This executes disposable PGlite and in-memory object writes, compares every
message ID/content/timestamp/sender/receipt set, checks counts and exact replay,
and does not apply the plan to a runtime. `--report` creates a new private report;
choose a new output path rather than overwriting an existing report.

When refreshing an authorized source export, choose the existing account with
access explicitly. An old gcloud quota project once pointed at a deleted project;
use per-command `wutzup-swift` quota/billing-project selection, not a global SDK
reconfiguration or new IAM/service-account credentials. Billing/access failures
are not authorization to enable billing, widen permissions or delete old data.

## Verification workflow

Define observable acceptance criteria before a meaningful change. Use isolated,
deterministic regression tests that fail for the old behavior. Cover normal,
invalid, authorization, replay/conflict and recovery paths. Compilation and
subjective review are insufficient evidence for changed behavior. Choose the
smallest credible set of independent checks for the actual risk.

### Native changes

From this repository:

```sh
python3 scripts/check-firebase-auth-only.py
bash scripts/test-archlife-backend.sh
bash scripts/test-offline-queue.sh
python3 scripts/test-offline-queue-mutations.py
WUTZUP_DERIVED_DATA_PATH=/tmp/wutzup-archlife-derived bash build.sh
```

The standalone Swift test executable validates transport restrictions, retry IDs,
wire decoding from executed SQL, citation handling and media response failures.
It is not an authenticated full-app UI test. For UI/state/lifecycle changes,
add relevant automated coverage and record simulator/device QA: identity,
offline/reconnect, error/retry, lifecycle cancellation, accessibility/VoiceOver,
Dynamic Type, keyboard behavior, and phone/tablet layouts as applicable.

The integrated signed-in simulator workflow is `bash scripts/test-archlife-e2e.sh`.
It creates its own Auth emulator, HTTPS test CA, Docker PostgreSQL/Hasura/MinIO
and simulator, using the real app project. Explicit `--embedded` replaces Hasura
and objects with PGlite/in-memory storage for hosted macOS CI; the Linux Docker
gate remains independently required. Read `docs/release-testing.md` before use.
Never erase an existing simulator or relax Release transport checks for testing.

### API, validation, authorization or AI changes

From TypeScript cloud; select all applicable checks:

Cloud/shared CI pins Node 24.13.1 and Yarn 1.22.22. Install dependencies with
`yarn install --frozen-lockfile` in the relevant TypeScript checkout when needed;
the native repository uses Xcode/Swift Package Manager, not an npm app build.

```sh
yarn check:wutzup
yarn build
yarn check:wutzup:format
yarn check:wutzup:parity
node scripts/sync-wutzup-schema.mjs --check
yarn tsx scripts/sync-wutzup-native-fixture.ts --check
yarn test:wutzup
yarn test:wutzup:integration
yarn test:wutzup:acceptance
yarn test:wutzup:mutation
yarn test:wutzup:auth
yarn test:wutzup:e2e
yarn check:wutzup:security
yarn test:wutzup:release /absolute/path/to/wutzup-swift
```

`test:wutzup:integration` exercises actual SQL in PGlite plus HTTP-to-SQL behavior.
`test:wutzup:auth` starts pinned Firebase CLI Auth emulation for `demo-wutzup`;
it requires Java (CI uses Temurin 21). Mutation checks use disposable copies,
not mutations of the user's source. Run broader `yarn test:acceptance` when
shared service integration is touched and the repository's applicable full unit
checks for broader changes. Do not change exclusions to hide unrelated failures.

AI evaluations are versioned, with explicit quality/latency/token/cost limits.
`yarn eval:wutzup --live` spends money and contacts the provider; use it only when
authorized. A synthetic text evaluation does not prove real research/image
quality, general translation accuracy, production persistence or push delivery.

### Schema/admin/runtime/secret changes

```sh
cd /Users/zernach/code/archlife-apps-runtime/services/python-cloud
PYTHON_DOTENV_DISABLED=1 .venv/bin/python -m unittest discover -s tests
PYTHON_DOTENV_DISABLED=1 .venv/bin/python scripts/test_wutzup_postgres.py

cd /Users/zernach/code/archlife-apps-runtime/scripts/runtime/runtime-tools
rustfmt --check --edition 2021 --config skip_children=true \
  src/bin/render.rs src/bin/doctor.rs src/bin/generate-secrets.rs src/bin/runtime-config.rs
cargo test --bin render --bin doctor --bin generate-secrets --bin runtime-config

cd /Users/zernach/code/archlife-apps-runtime
python3 -m unittest discover -s scripts/secrets/tests -p 'test_onboard_wutzup.py'
```

Python uses the repository environment (`uv sync --frozen` / `uv run` in CI).
The real PostgreSQL test requires `pg_config`, `initdb`, `pg_ctl` and psycopg2; it
starts an isolated Unix-socket-only cluster with cleanup, independent-connection
concurrency/permissions checks and a fixture latency budget. It is stronger than
PGlite for locks, but is not live Hasura, capacity or backup/restore evidence.
Run dependency/security checks for affected packages and redact secrets in any
recorded output. For config changes, verify secret presence, source equality,
DEV/PROD plus blue/green propagation and replay without exposing values.

### CI and evidence boundaries

- Native: `.github/workflows/archlife-backend.yml` runs the strict Auth/Core
  dependency guard, Debug/Release contracts and builds, queue/draft regressions
  and five queue/privacy mutations on macOS.
- Joint release: cloud `wutzup-api-e2e` runs actual Docker Hasura/Postgres/S3 and
  the critical dependency gate; `wutzup-swift-e2e` checks out the public native
  candidate and runs the real app UI with explicit embedded infrastructure plus
  its Release build. Both block the existing deployment webhook. Publish matching
  native changes before requesting this joint gate; manual dispatch accepts an
  exact `wutzup_native_ref`. Local results do not prove remote CI passed.
- Cloud: `.github/workflows/archlife-runtime-deploy.yml` includes Wutzup build,
  strict types, formatting, parity, tests, mutations, BDD and Auth emulation as
  well as other apps' gates; optional paid evaluations are separate.
- Python: `.github/workflows/plantsnursery-quality.yml` runs schema/application
  tests and the real PostgreSQL test despite its historical filename.
- Shared types: `.github/workflows/wutzup-contracts.yml` builds/packages and tests
  narrow copying. Runtime CI includes the secret-onboarding regression suite.

Record commands actually run, target environment, observed results and remaining
risks. Separate unit/contract, SQL integration, Auth emulator, simulator build,
signed-in native UI, real S3/APNs, deployment and backup/restore proof. A passing
liveness route or `ready: true` with `push_configured: false` is not push proof.
For documentation-only changes, validate paths, commands, internal consistency
and secret hygiene; application builds are not automatically required.

## Live rollout and recovery boundaries

The October local migration report records no live target import, remote secret
publication, Firebase retirement, IAM/billing change or production/device/restore
proof. Recheck current deployment state before a new release; never turn those
historical statements into an unsupported current claim.

For an explicitly authorized cutover, prepare and verify all artifacts first:

1. Review exact revisions across the separate repositories and the selected
   environment, source snapshot, deferred-media decision, credentials and rollback.
2. Publish the selected scoped secrets through the existing vault workflow;
   converge DB roles, ordered migrations, private Hasura source/functions and
   service environment. Preserve existing database credentials and other apps.
3. Inspect current `bin/archlife` help/implementation. `init` is not namespace-only:
   it can sync repositories, recreate shared Hasura, build the Python image and
   run MinIO/RabbitMQ/database initialization. `apply-migrations <local|dev|prod>`
   does not by itself provision/prove all namespace infrastructure.
4. Freeze legacy writes and refresh/verify the final source snapshot so messages
   arriving after the old export are not lost. Apply the reviewed plan before
   enabling new-client traffic or bootstrapping profiles into an empty target.
5. Deploy the exact reviewed/pushed revisions through the runtime's supported
   release workflow. Health-gate the candidate color; verify both public DEV
   and PROD as applicable, not just the environment that happened to update.
6. Prove real Firebase sign-in, profile/chat persistence, reload from another
   signed-in session, outsider denial, receipts/cursors, retries, actual private
   media and physical-device APNs. Inspect redacted failures and configuration flags.
7. Confirm `wutzupdb` in actual backup inventory and validate a disposable restore.
   Runtime `verify <snapshot>`, `backup-verify` and `restore-drill` have different
   scopes; checksums alone do not prove a usable restore. Never restore over live
   user data to test a backup. Retire old Firebase resources only in an authorized,
   separately verified phase.

Push/deploy automation must be inspected, not assumed. Runtime instructions
describe a shared 15-second debounce worker and latest-wins local autostart.
On this audit, `scripts/hooks/pre-push` and cloud `.husky/pre-push` explicitly
exit early with push-triggered runtime deployment disabled, while cloud GitHub
Actions still has a push-triggered deploy webhook. Hook installation alone does
not prove activation, and a push can still cause a deployment. Do not re-enable
hooks or change deployment automation as a side effect. Real `autostart` can
preempt another local worker; `--status`/`--dry-run` are the read-only inspection
forms. Check current source before using any of these operational paths.

## Known discrepancies and troubleshooting

| Symptom / discrepancy | What to inspect before changing behavior |
| --- | --- |
| Blank Firebase/API/APNs fields in a template | Compare actual ignored app/service/catalog/generated envs through presence/equality checks; `.example` values are placeholders |
| Firebase sign-in works but chats fail | API base URL, signed token project/account state, SQL profile bootstrap, Hasura function/source, selected DB and readiness; identity alone is insufficient |
| `identity_unconfigured` / `identity_unavailable` / 401 | Existing plist/client-key parity, correct audience, disabled/revoked/deleted account, Auth emulator restrictions and certificate/network access |
| `persistence_unconfigured` / `persistence_unavailable` | Selected private Hasura endpoint/secret, source/function tracking, actual migration state, GraphQL errors and environment routing |
| `recent_login_required` | Reauthenticate before account deletion; do not remove the recent-auth guard |
| `idempotency_conflict`, `request_in_progress`, `revision_conflict` | Stable request/message IDs and unchanged intent, active lease and current revision; conflict is not permission to overwrite evidence |
| Missing/stale receipts or typing | Sync cursor ordering, membership, polling lifecycle, server expiry, request errors and cache state |
| Media failure / broken images | S3 config/reachability, matching renderer origin, capability metadata, valid HTTP image bytes; never cache an error body or fall back to legacy Firebase Storage |
| `push_configured: false` | All three APNs variables in the actual server environment; Team ID alone is insufficient |
| APNs rejection / no device delivery | Key ID/team/private key pair, signed bundle entitlement, sandbox/production token, token registration timing, SQL outbox leases/retries and device permission |
| Native Firebase boundary regresses | Xcode links Auth only; `check-firebase-auth-only.py` allowlists Auth/Core imports and Firebase products. Functions/Crashlytics links were removed with the release tests; rebuild and run the guard after dependency edits |
| Native offline account isolation | Queue v2 preferences are account-owned and activated by AppState; drafts bind to the view's original account. Old unowned queue/draft keys are retained for explicit recovery, never reassigned. Run queue regressions/mutations and the account-switch UI scenario; check cancellation and acknowledgements across awaits |
| Old build resolves the previous checkout path | Use `build-archlife/` or an isolated `WUTZUP_DERIVED_DATA_PATH`; preserve valuable existing caches/data |
| Whole-repository checks fail outside this change | Historical OpenJob unit failures, dependency audit findings, Rust formatting drift and Swift warnings are documented in the runtime report. Reproduce current failures, identify ownership and report them; do not call the whole suite green or silently suppress them |

The user wants repeatable end-to-end workflows with evidence, not scaffold-only
completion. At handoff state what changed, why, how it was verified, which live
layers remain unrun and which external blockers remain. Update this guide when
changing a contract, path, environment, command or operational boundary, and keep
private payloads/credentials out of the documentation.

## Artifact-bound store operations

`bash scripts/mobile-release.sh status|upload|submit|release` delegates to the
shared bootstrap store tool. `MAC_MINI_BOOTSTRAP_ROOT` selects that checkout;
`--plan` selects an explicit release plan. The default current plan is
`config/mobile-releases/wutzup-2.0.0.json` there. Plans pin a previously signed
Mini-local IPA and its checksum; store commands never rebuild or choose the
latest build. They preserve manual public release and save provider receipts on
both Macs. See the [shared workflow](../../mac-mini-bootstrap/docs/mobile-releases.md).
Store upload/review requires the user's authorization; the November 6 task
authorized 2.0.0 (2), which reached `WAITING_FOR_REVIEW`. A future version uses
its own reviewed plan and authorization. Review submission and Apple's approval
do not establish live cutover, device QA, APNs, backup restoration or public
rollout readiness. Preserve those release checks above.
