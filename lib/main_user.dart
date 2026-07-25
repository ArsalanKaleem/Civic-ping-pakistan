// Citizen app entry point — runs on the web AND as the Android app.
//
// Web:     flutter run -d chrome  -t lib/main_user.dart \
//              --dart-define=API_BASE_URL=http://localhost:8000
// Android: flutter run -d android -t lib/main_user.dart \
//              --dart-define=API_BASE_URL=http://10.0.2.2:8000
//          (see ANDROID.md for permissions, cleartext dev config, SHA-1)
// Build:   flutter build web|appbundle -t lib/main_user.dart \
//              --dart-define=API_BASE_URL=https://api.your-domain.pk

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/bootstrap.dart';
import 'services/auth_service.dart';
import 'user/auth/sign_in_screen.dart';
import 'user/user_shell.dart';

Future<void> main() async {
  runApp(await bootstrap(
    title: 'CivicPing Pakistan',
    home: const _UserRoot(),
  ));
}

class _UserRoot extends StatelessWidget {
  const _UserRoot();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return auth.isSignedIn ? const UserShell() : const SignInScreen();
  }
}
