# Firebase Auth only

Wutzup retains its existing Firebase Auth project, `wutzup-swift`, client
configuration and user IDs. The default `firebase.json` configures only the Auth
emulator. Native application data and backend logic use the Archlife TypeScript
API and private `wutzupdb` database. Media uses Archlife S3; push uses direct APNs.

For Auth development, from this directory:

```sh
firebase emulators:start --only auth --project demo-wutzup
```

The Firebase Auth emulator is rejected by the production API. Service integration
tests start their own isolated Auth emulator; no Firestore emulator or Firebase
relay is part of the new test or runtime path.

`functions/`, Firestore/Storage rules, indexes, seed utilities and
`firebase.legacy.json` preserve the old implementation for reference and controlled
rollback. The original server `.env` is ignored; its Wutzup OpenAI key is reused
through runtime secret onboarding. The historical scripts may mutate the old
project and are not the current onboarding/deployment workflow.

The read-only export, media recovery, offline import preparation and guarded
application tools live in Archlife TypeScript cloud under
`scripts/migrations/wutzup.ts`. No legacy source data or deployed Firebase
functions have been deleted. See [migration](../docs/backend-migration.md) and
[verification](../docs/backend-verification.md).
