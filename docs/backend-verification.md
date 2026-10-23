# Wutzup backend verification

The current migration moves application data and API logic into Archlife while
retaining Firebase Auth only. The full acceptance matrix, private export/import
counts, reproducible commands, dependency findings and release boundaries are
recorded in the runtime's `docs/wutzup-backend-verification.md` and
`docs/wutzup-data-acceptance.md`.

Local native checks on 21 October 2026 passed:

```sh
python3 scripts/check-firebase-auth-only.py
bash scripts/test-archlife-backend.sh
WUTZUP_DERIVED_DATA_PATH=/tmp/wutzup-archlife-derived bash build.sh
```

The standalone Swift executable validates allowed/denied API origins and paths,
redirect rejection, stable retry IDs, response decoding from executed PostgreSQL
functions, research links, and media response/error handling. The unsigned iOS
simulator build compiles all product sources with Firebase Core/Auth only. It
retains existing preview/unused-value/framework metadata warnings; successful
compilation is not a real-user or device test.

The API has 29 focused passing behavior/HTTP/provider/security/import tests and
10 passing SQL/API integration scenarios. A real PostgreSQL cluster additionally
checks cross-connection locks, quotas, denied public permissions and latency.
Firebase Auth integration uses the Auth emulator only and includes revoked users.
CI codifies these service checks and native boundary/contracts/build checks.

Read-only source export and isolated import verification preserved **35 profiles,
74 conversations and 3,086 messages**, including exact IDs/content/timestamps and
receipt sets. Three of seven media references were recovered from existing local
caches. Four remain unavailable due to closed legacy Google billing and are
preserved in private recovery records, not silently discarded.

No deployment, live target import, remote vault publication, Firebase retirement
or billing/IAM change occurred. A real signed-in native journey, independent
session reload, cross-user denial, actual S3 media, physical-device APNs and
backup/restore remain release gates. See [migration ownership](backend-migration.md).
