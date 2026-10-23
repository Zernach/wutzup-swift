# Wutzup Archlife database migration

Firebase Auth remains the existing identity provider (`wutzup-swift`). All
application data and backend operations move to the Archlife ecosystem:

| Responsibility | Owner |
| --- | --- |
| Sign-in, password reset, identity tokens | Existing Firebase Auth |
| Profiles, tutors, conversations, messages, receipts, presence | Private Archlife PostgreSQL `wutzupdb` |
| Data and eight AI operations | Existing Archlife TypeScript API, `/api/wutzup` |
| Private schema/migrations, Hasura registration, admin and backups | Archlife runtime/Python schema tooling |
| Images and generated GIFs | Archlife private S3 objects, API capability URLs |
| Push delivery | Durable SQL outbox, direct APNs |
| Local caching and offline send IDs | Existing SwiftData and Swift app |

The native product links Firebase Core/Auth only. Default `firebase/firebase.json`
configures the Auth emulator only. Historical Python functions, Firestore rules
and `firebase.legacy.json` remain rollback/reference source; they are not the
active application API. No TypeScript Firebase event relay is required.

Swift uses one authenticated transport, validates API origins and rejects
redirects. Polling is bounded, backs off on errors and cancels on account/lifecycle
changes. Group invitations merge membership on the server; revision checks fence
other group edits. Image errors are validated before caching. Tutor IDs and all
legacy Firebase UIDs remain stable.

Debug defaults to `https://api-dev.archlife/api/wutzup`; Release defaults to
`https://api.archlife.org/api/wutzup`. `WUTZUP_API_BASE_URL` supports the selected
local edge port (18443 is allowed). These configured URLs are not deployment proof.
No web frontend replaces this Swift application.

`PROJECTS.WUTZUP` in the TypeScript API selects the original Wutzup OpenAI key via
`OPENAI_4_API_KEY_WUTZUP`, with no fallback to another app's key. Credentials live
in ignored runtime/service catalogs. Token verification uses public certificates
and the existing public Firebase Auth client configuration, without a new
service-account private key.

The private reviewed import preserves 35 profiles (20 tutors), 74 conversations
and 3,086 messages. Three media files were recovered from local caches; four are
unavailable because Google reports the old Storage billing account closed.
Exact original URLs and references remain in private recovery records and the
source export. The import has passed isolated SQL execution/replay only. Live
migration, release, real-session persistence, APNs/S3 and backup/restore are
separate operational checks. See [verification](backend-verification.md).
