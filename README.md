# LiveVacTrack

LiveVacTrack is the Android app for the CC105 Groupata system: a livestock
vaccination and movement-permit tracker for a municipal veterinary office.
Farmers are **not** app users. Five staff roles share one app, plus a separate
super admin who provisions accounts:

| Role | Wire value | What they do |
| --- | --- | --- |
| Super admin | `admin` | Create staff accounts for the other roles |
| Registry | `registry` | Register farmers and animals; also create staff |
| Veterinarian | `vet` | Record vaccinations (append-only) |
| Permit clerk | `clerk` | Issue movement permits |
| Checkpoint inspector | `inspector` | Scan and verify permits |
| Disease control | `disease_control` | Declare area quarantines |

## Demo mode (default)

The app runs without any Firebase project. Data comes from an in-memory store
and permits are signed with a local HMAC key that mirrors the Cloud Functions
signer.

```bash
flutter pub get
flutter run
```

Demo accounts (password `demo1234`):

| Email | Role |
| --- | --- |
| `admin@livevactrack.test` | Super admin |
| `registry@livevactrack.test` | Registry |
| `vet@livevactrack.test` | Veterinarian |
| `clerk@livevactrack.test` | Permit clerk |
| `inspector@livevactrack.test` | Checkpoint inspector |
| `disease@livevactrack.test` | Disease control |

The sign-in screen also has one-tap chips for each demo account. Use
**Profile → Simulate offline mode** to demonstrate that an offline checkpoint
scan shows **UNVERIFIED**, never **VALID**.

### Creating more staff accounts

Sign in as the **super admin** (`admin@livevactrack.test`) or the registry
account, open the **Staff** tab, and choose **Add staff account**. This creates
an Auth user, a `users/{uid}` document and a role claim. It works in demo mode
too (the account is added to the in-memory demo accounts and appears as a
sign-in chip). The super admin role is bootstrapped manually (Firebase Console
or `scripts/provision-user.js`) and cannot be created from the app.

### Areas and the PSGC picker

Area dropdowns (farmer registration, staff provisioning and quarantine
declaration) use the Philippine Standard Geographic Code API at
`https://psgc.cloud`. Live mode cascades Province → City/Municipality →
Barangay through `/api/v2`, so each step fetches only a few hundred rows
instead of the ~42,000-row national barangay list. Responses are cached in
`SharedPreferences` for seven days, and the stale cache is used when the
device is offline. The stored `areaId` is the PSGC barangay code; the display
name is kept alongside it for staff profiles.

Demo mode stays fully offline and falls back to the four seeded
`AppConfig.areas` (poblacion, san-jose, sta-cruz, bagong-sikat).

## Core rules enforced by the design

- A permit can only be issued when the animal is vaccinated for the travel
  date **and** its area has no active quarantine.
- Permit validity is `min(endOfDay(travelDate), endOfDay(vaccinatedUntil))`.
- Permits are written only by Cloud Functions. The signing secret never ships
  in the APK.
- Checkpoint verification checks the HMAC signature, the permit status and the
  valid-until date. A missing or altered code returns **INVALID**.
- Offline verification returns **UNVERIFIED** and marks the result as
  non-authoritative, even when a cached permit is shown.
- Declaring a quarantine revokes every issued permit in that area and blocks
  new ones.
- Lists are paginated; the app does not use FCM push notifications.
- Checkpoint scans are logged per permit and per animal; the animal detail
  screen shows that animal's scan history, newest first.

## Project structure

```
lib/
  core/            config, theme, date/QR helpers, PSGC location service, errors
  data/
    demo/          in-memory store, seed data, demo signer
    enums/         role, status and scan-result wire values
    models/        Firestore-shaped models
    repositories/  abstract contracts + demo implementations
    firebase/      Auth/Firestore/Functions implementations
    services/      AuthService and staff-account contracts
  state/           Riverpod providers (repositories, session, lists)
  pages/           screens that wire providers to organisms
  ui/
    atoms/         text, buttons, fields, badges, QR view
    molecules/     list tiles, banners, dialogs, result panel, location picker
    organisms/     login form, shells, registry/permit/quarantine views
    templates/     auth, shell, list, form, scan, detail layouts
functions/         Node 20 Cloud Functions
firestore.rules    staff-only reads; no direct permit/quarantine writes
firestore.indexes.json
firebase.json
```

Atomic-design rule: nothing under `lib/ui/` imports Firebase or Riverpod. Pages
own state and pass plain data/callbacks down.

## Live Firebase setup

1. Create a Firebase project and install the CLI:
   ```bash
   npm install -g firebase-tools
   firebase login
   ```
2. From the project root, configure FlutterFire (Android only is enough):
   ```bash
   flutterfire configure --project=<your-project-id>
   ```
   This generates `lib/firebase_options.dart` and `android/app/google-services.json`.
   `main.dart` already calls `Firebase.initializeApp()` for live builds.
3. Enable **Authentication → Email/Password** and **Cloud Firestore**.
4. Upgrade the project to the **Blaze** plan (required to deploy Cloud
   Functions and use secrets).
5. Set the signing secret:
   ```bash
   firebase functions:secrets:set PERMIT_SIGNING_SECRET
   ```
   Use a long random value. The app never sees it.
6. Deploy rules, indexes and functions:
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes,functions
   ```
7. Create staff accounts in Authentication, then create `users/{uid}` documents:
   ```json
   {
     "displayName": "Carla Dizon",
     "role": "clerk",
     "areaId": "0102801001",
     "areaName": "Poblacion, City of Batac, Ilocos Norte"
   }
   ```
   Roles: `admin`, `registry`, `vet`, `clerk`, `inspector`, `disease_control`.
   `areaId` is a PSGC barangay code in live mode; `areaName` is what the
   profile screen displays.
   Optionally mirror the role into a custom claim so rules avoid the extra
   `users` read:
   ```js
   admin.auth().setCustomUserClaims(uid, { role: 'clerk' });
   ```
8. Staff accounts can also be provisioned from the app: sign in as the super
   admin or registry, open **Staff → Add staff account**. This uses the
   `createStaffAccount` callable function, which is restricted to those two
   roles. To create an account from a terminal instead, see
   `scripts/provision-user.js` (requires a service account key).
   **Spark (free) plan:** export the built-in demo accounts (password
   `demo1234`) to Firebase without Cloud Functions or a service account:
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   node scripts/seed-demo-accounts.js
   node scripts/seed-demo-data.js
   ```
   `seed-demo-data.js` copies the demo farmers, animals, vaccinations,
   permits, quarantines and checkpoint scans into Firestore, linked to the
   demo accounts' real UIDs. Both scripts are safe to re-run; add `--reset`
   to `seed-demo-data.js` to overwrite those records with fresh copies. After that, the super admin creates further
   accounts from **Staff → Add staff account**; the app writes them straight
   to Firebase Auth and `users/{uid}` (no function needed). Those accounts are
   not listed under DEMO ACCOUNTS on the login screen.
9. Run against the live project:
   ```bash
   flutter run --dart-define=DEMO_MODE=false
   ```

### Local emulator

```bash
firebase emulators:start
```

For the Functions emulator, copy `functions/.env.example` to
`functions/.secret.local` and keep `PERMIT_SIGNING_SECRET` consistent for the
session. Point the app at the emulator by adding the usual
`useFunctionsEmulator` / `useFirestoreEmulator` calls in `firebase_bootstrap.dart`
when developing locally.

## Cloud Functions contract

| Function | Caller | Purpose |
| --- | --- | --- |
| `issuePermit` | `clerk` | Re-checks vaccination + quarantine, signs, writes the permit |
| `verifyPermit` | any staff | Checks the signature/status/expiry and logs a verification |
| `declareQuarantine` | `disease_control` | Creates the quarantine and revokes issued permits |
| `createStaffAccount` | `admin`, `registry` | Creates an Auth user, `users/{uid}` document and role claim |
| `onVaccinationCreated` | trigger | Updates the animal's cached vaccination window |
| `onQuarantineCreated` | trigger | Safety net that revokes permits written around the callable |
| `refreshVaccinationStatus` | scheduled | Marks animals expired after their valid-until date |

`issuePermit` returns `{ permitId, permit }`; `verifyPermit` returns
`{ result, message, signatureValid, checkedAt, permitId, permit }`;
`declareQuarantine` returns `{ revokedCount, quarantineId }`.

Signing is HMAC-SHA256 over the permit ID, lowercase hex. The demo signer in
`lib/data/demo/demo_signing.dart` produces the same value with the demo secret.

## Offline behaviour

- Firestore persistence is enabled in live mode.
- The checkpoint reads a cached permit when offline but reports **UNVERIFIED**
  with `signatureValid: false`.
- The UI shows a warning banner and the last-synced time. The "last synced"
  timestamp only advances after an online verification.
- No verification result is ever cached as authoritative.

## Tests

```bash
flutter analyze
flutter test
```

The suite covers the demo signer, permit issuance eligibility, quarantine
blocking, online verification outcomes (valid/revoked/expired/invalid), the
offline UNVERIFIED rule, QR parsing, and the six role shells (including the
super admin).

## Build

```bash
flutter build apk --debug
# or, for the demo build:
flutter build apk --release
```

## Deliberately deferred

- FCM push notifications (not used; alerts are pulled from Firestore).
- Firebase Storage, Crashlytics and Analytics.
- Realtime Database.
- A separate `areas` collection; live areas come from PSGC and demo areas are
  seeded in `AppConfig.areas`.
