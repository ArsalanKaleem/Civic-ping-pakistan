# CivicPing Frontend

One Flutter codebase, two applications:

| Entry point | Audience | Run with |
|---|---|---|
| `lib/main_user.dart` | Citizens — **web** | `flutter run -d chrome -t lib/main_user.dart` |
| `lib/main_user.dart` | Citizens — **Android** (same code) | `flutter run -d android -t lib/main_user.dart` — see [ANDROID.md](./ANDROID.md) |
| `lib/main_admin.dart` | Admin (desktop) | `flutter run -d windows -t lib/main_admin.dart` |

Add `--dart-define=API_BASE_URL=http://localhost:8000` (or your deployed API).

## First-time setup

```bash
flutter create . --platforms=web,windows,macos,linux,android   # generates platform folders, keeps lib/
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure --out lib/firebase_options.dart  # your Firebase project
```

Until `flutterfire configure` is run, both apps show a setup screen with
instructions (the placeholder `lib/firebase_options.dart` explains it too).

## Structure

```
lib/
  main_user.dart / main_admin.dart   entry points
  core/       bootstrap (Firebase + providers), theme (design system),
              api_client (auth-aware HTTP), config
  models/     enums, report, social_post, authority (+ AdminStats)
  services/   auth (Firebase Google/email + guest), reports, admin, location
  user/       sign-in hero, shell (map/feed), report flow, detail, success
  admin/      sign-in, gate (is_admin check), shell (nav rail), dashboard,
              social queue, reports table, authorities CRUD, email logs
  widgets/    badges, brand mark, empty states
```

## Notes

- **Admin sign-in is email/password** (Google popup sign-in is a browser flow;
  the console also runs in Chrome via `-d chrome` if you prefer Google there).
- Create your admin account once via the citizen web app's registration using
  the email listed in the backend's `ADMIN_EMAILS` — the backend promotes it
  to admin on first sign-in.
- Web geolocation requires HTTPS in production (localhost is exempt).
- Fonts (Fraunces/Inter) load via google_fonts at runtime.
