# Firebase Setup for Chat

## Canonical project (post-migration)

| Source | `project_id` | Status |
|--------|----------------|--------|
| `android/app/google-services.json` | **casazero-a39ba** | ✅ NEW (use this everywhere) |
| `lib/firebase_options.dart` (android) | **casazero-a39ba** | ✅ |
| `ios/Runner/GoogleService-Info.plist` | casazero-3ab94 | ❌ STALE — download new plist from Console |
| `lib/firebase_options.dart` (ios) | casazero-3ab94 | ❌ STALE until `flutterfire configure` |

**custom-token-mismatch** means Laravel Kreait `createCustomToken()` uses a service account from a **different** project than the Flutter app. Fix on Laravel: replace `storage/app/firebase/*.json` (or `.env` `FIREBASE_CREDENTIALS`) with the **casazero-a39ba** service account, then redeploy.

After login, check Flutter logs for:
`TOKEN_AUD_MISMATCH: JWT aud="..." but Firebase app projectId="casazero-a39ba"`.

Flutter uses **only** the top-level `firebase_token` from `POST /user/login` (stored locally). Do **not** call `/user/firebase-token`.

## Android Configuration

### 1. Package Name
- **Required**: `com.example.casazero` (must match `android/app/build.gradle.kts` `applicationId`)
- Verify in Firebase Console → Project Settings → Your apps → Android app

### 2. SHA-1 Fingerprint
- **Required** for Firebase Auth (custom token) and Google Sign-In
- Get debug SHA-1: `cd android && ./gradlew signingReport` (or `gradlew.bat signingReport` on Windows)
- Add SHA-1 in Firebase Console → Project Settings → Your apps → Android → Add fingerprint
- After adding SHA-1: **Download new `google-services.json`** and replace `android/app/google-services.json`

### 3. google-services.json
- Must be in `android/app/google-services.json`
- Must contain `package_name: "com.example.casazero"`
- After any Firebase Console change (SHA-1, new app): replace file and run `flutter clean`

### 4. Resolve DEVELOPER_ERROR
If you see `DEVELOPER_ERROR` or Auth failures:
1. Confirm SHA-1 is added in Firebase Console (both debug and release if needed)
2. Download fresh `google-services.json` after adding SHA-1
3. Run `flutter clean`
4. Rebuild: `flutter run`
5. Ensure Firebase custom token from Laravel uses the same UID format as `group.members`

### 5. After Changes
```bash
flutter clean
flutter pub get
flutter run
```

## Firestore / Storage Rules Deployment

Deploy rules via Firebase CLI:
```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
```

## Verification Checklist

- [ ] Firebase UID matches Laravel user ID (string, e.g. "19")
- [ ] `group.members` in Firestore contains Firebase UIDs exactly
- [ ] Messages load in real time
- [ ] Text messages send successfully
- [ ] Image messages upload and display
- [ ] Multi-user: different users see each other's messages
- [ ] Multi-admin: admin UIDs in `group.members` can send/receive
