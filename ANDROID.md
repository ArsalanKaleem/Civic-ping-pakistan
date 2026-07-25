# Citizen app on Android

The same `lib/main_user.dart` runs as the Android citizen app. After
`flutter create . --platforms=web,windows,android` do these one-time steps:

## 1. Permissions — android/app/src/main/AndroidManifest.xml

Inside `<manifest>` (above `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

## 2. Local development against http:// (dev only)

Android blocks cleartext HTTP by default. To talk to your local backend during
development, add to the `<application …>` tag:

```xml
android:usesCleartextTraffic="true"
```

Remove this for production builds — the deployed app must use an HTTPS API.

## 3. Firebase + Google Sign-In

- Re-run `flutterfire configure` and include **android** (it registers the
  package name and writes `android/app/google-services.json`).
- Google Sign-In on Android additionally requires your app's **SHA-1**
  fingerprint in Firebase → Project settings → Your Android app:

  ```bash
  cd android && ./gradlew signingReport   # copy the debug SHA-1
  ```

  Add it, download the updated `google-services.json` (or re-run
  `flutterfire configure`), and rebuild. Email/password and guest mode work
  without this step; only the Google button needs it.

## 4. Run

```bash
# Emulator (10.0.2.2 = your computer's localhost):
flutter run -d android -t lib/main_user.dart \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000

# Physical phone: use your computer's LAN IP instead.
```

## 5. Release build

```bash
flutter build appbundle -t lib/main_user.dart \
  --dart-define=API_BASE_URL=https://api.your-domain.pk
```

Upload the `.aab` from `build/app/outputs/bundle/release/` to Google Play
Console. Remember: release builds have a different SHA-1 (your upload/signing
key) — add that fingerprint to Firebase too, or Google Sign-In will fail in
production while working in debug.
